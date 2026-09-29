'use strict';

const crypto = require('crypto');
const {onSchedule} = require('firebase-functions/v2/scheduler');
const admin = require('firebase-admin');

if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();

const RESOURCE_URL = process.env.GAEZ_V5_CROP_SUMMARY_URL ||
  'https://api.data.apps.fao.org/api/v2/bigquery?sql_url=' +
  encodeURIComponent('https://data.apps.fao.org/catalog/dataset/a55c337e-f7e6-4d2f-aa8e-6d2199171c37/resource/fef86116-be49-4ddc-8317-66cd368d4fda/download/gaez-crop-summary-query.sql');

const BATCHES_PER_RUN = 3;
const ROWS_PER_BATCH = 5000;
const LOCK_MS = 15 * 60 * 1000;

function parseCsvLine(line) {
  const cells=[]; let cell=''; let quoted=false;
  for (let i=0;i<line.length;i++) {
    const ch=line[i];
    if (ch === '"') {
      if (quoted && line[i+1] === '"') { cell+='"'; i++; }
      else quoted=!quoted;
    } else if (ch === ',' && !quoted) { cells.push(cell); cell=''; }
    else cell+=ch;
  }
  cells.push(cell);
  return cells;
}

function parseCsv(text) {
  const lines=String(text||'').replace(/^\uFEFF/,'').split(/\r?\n/).filter(line=>line.trim());
  if (!lines.length) return [];
  const headers=parseCsvLine(lines[0]).map(v=>v.trim());
  return lines.slice(1).map(line => {
    const values=parseCsvLine(line);
    return Object.fromEntries(headers.map((h,i)=>[h, values[i] ?? '']));
  });
}

function extractRows(payload, contentType) {
  if (/json/i.test(contentType)) {
    if (Array.isArray(payload)) return payload;
    if (Array.isArray(payload?.data)) return payload.data;
    if (Array.isArray(payload?.rows)) return payload.rows;
    if (Array.isArray(payload?.results)) return payload.results;
    if (Array.isArray(payload?.data?.rows)) return payload.data.rows;
    return [];
  }
  return parseCsv(payload);
}

function normalizeRows(rows) {
  return rows.map(row => {
    const out={};
    for (const [key,value] of Object.entries(row)) {
      const clean=String(value ?? '').trim();
      if (!clean) continue;
      const numeric=clean.replace(/,/g,'');
      out[key]=/^-?\d+(?:\.\d+)?$/.test(numeric) ? Number(numeric) : clean;
    }
    return out;
  }).filter(row=>Object.keys(row).length);
}

function rowField(row, names) {
  for (const name of names) {
    if (row?.[name] !== undefined && row?.[name] !== null && String(row[name]).trim()) return String(row[name]).trim();
  }
  return '';
}

function countryKey(row, byName) {
  const raw=rowField(row,['iso3','ISO3','country_iso3','countryIso3','adm0_iso3','country_code','Country ISO3','country','Country','area','Area']);
  if (/^[A-Za-z]{3}$/.test(raw)) return raw.toUpperCase();
  return byName.get(raw.toLowerCase()) || '';
}

function cropKey(row) {
  return rowField(row,['crop','Crop','crop_name','Crop Name','commodity','Commodity','crop_lut']).toLowerCase();
}

async function acquireLease(stateRef) {
  const now=Date.now();
  let acquired=false;
  await db.runTransaction(async tx=>{
    const snap=await tx.get(stateRef);
    const d=snap.exists ? snap.data()||{} : {};
    const lockedUntil=Number(d.lockedUntilMs||0);
    if (lockedUntil > now) return;
    tx.set(stateRef,{lockedUntilMs:now+LOCK_MS,lastRunStartedAt:admin.firestore.FieldValue.serverTimestamp()},{merge:true});
    acquired=true;
  });
  return acquired;
}

exports.aurenGaezV5GlobalIngestScheduled = onSchedule(
  {schedule:'every 15 minutes', timeZone:'Africa/Khartoum', timeoutSeconds:540, memory:'512MiB'},
  async () => {
    const stateRef=db.collection('auren_ingest_state').doc('gaez_v5_global');
    if (!(await acquireLease(stateRef))) return null;

    try {
      const res=await fetch(RESOURCE_URL,{
        headers:{accept:'text/csv,application/json,text/plain'},
        signal:AbortSignal.timeout(120000)
      });
      if (!res.ok) throw new Error('GAEZ v5 resource request failed: '+res.status);
      const body=await res.text();
      const contentType=String(res.headers.get('content-type')||'');
      const parsedPayload=/json/i.test(contentType) ? JSON.parse(body) : body;
      const rows=normalizeRows(extractRows(parsedPayload,contentType));
      if (!rows.length) throw new Error('No GAEZ v5 crop summary rows found.');

      const registrySnap=await db.collection('auren_global_countries').select('iso3','name').get();
      const byName=new Map();
      registrySnap.forEach(doc=>{
        const d=doc.data()||{};
        const iso3=String(d.iso3||doc.id||'').trim().toUpperCase();
        const name=String(d.name||'').trim().toLowerCase();
        if (/^[A-Z]{3}$/.test(iso3)&&name) byName.set(name,iso3);
      });

      const stateSnap=await stateRef.get();
      const offset=Math.max(0,Number(stateSnap.data()?.offset||0));
      let totalStored=0;
      let nextOffset=offset;
      const countries=new Set();
      const crops=new Set();
      const resourceSha256=crypto.createHash('sha256').update(body).digest('hex');

      for (let batchIndex=0;batchIndex<BATCHES_PER_RUN && nextOffset<rows.length;batchIndex++) {
        const selected=rows.slice(nextOffset,nextOffset+ROWS_PER_BATCH);
        const groups=new Map();
        for (const row of selected) {
          const iso3=countryKey(row,byName);
          const crop=cropKey(row);
          if (!iso3) continue;
          const key=iso3+'|'+crop;
          if (!groups.has(key)) groups.set(key,[]);
          groups.get(key).push({iso3,crop,row});
        }

        for (const group of groups.values()) {
          for (let i=0;i<group.length;i+=400) {
            const chunk=group.slice(i,i+400);
            const batch=db.batch();
            chunk.forEach(item=>{
              const stableId=crypto.createHash('sha256').update(item.iso3+'|'+item.crop+'|'+JSON.stringify(item.row)).digest('hex');
              batch.set(db.collection('auren_gaez_v5_crop_summary_rows').doc(stableId),{
                source:'FAO GAEZ v5 Crop Summary Data',
                version:'GAEZ v5',
                verification:{provider:'FAO',catalog:'Crop Summary Data',verifiedByCatalog:true},
                countryKey:item.iso3,
                cropKey:item.crop,
                row:item.row,
                resourceUrl:RESOURCE_URL,
                resourceSha256,
                importedAt:admin.firestore.FieldValue.serverTimestamp(),
                ingestionMode:'scheduled_global'
              },{merge:true});
            });
            await batch.commit();
            totalStored+=chunk.length;
          }
        }

        selected.forEach(row=>{
          const iso3=countryKey(row,byName);
          const crop=cropKey(row);
          if (iso3) countries.add(iso3);
          if (crop) crops.add(crop);
        });
        nextOffset += selected.length;
      }

      const complete=nextOffset>=rows.length;
      await stateRef.set({
        offset:complete?0:nextOffset,
        totalRows:rows.length,
        complete,
        lastRunAt:admin.firestore.FieldValue.serverTimestamp(),
        lastStored:totalStored,
        lastCountryCount:countries.size,
        lastCropCount:crops.size,
        resourceSha256,
        resourceUrl:RESOURCE_URL,
        lockedUntilMs:0
      },{merge:true});

      return null;
    } catch (error) {
      await stateRef.set({
        lastError:String(error?.message||error).slice(0,1000),
        lastErrorAt:admin.firestore.FieldValue.serverTimestamp(),
        lockedUntilMs:0
      },{merge:true});
      throw error;
    }
  }
);
