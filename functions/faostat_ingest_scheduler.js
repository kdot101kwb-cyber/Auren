'use strict';

const {onSchedule} = require('firebase-functions/v2/scheduler');
const admin = require('firebase-admin');

if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();

const DOMAINS = ['crops_livestock','land_use','trade','food_balances','prices','fertilizers'];
const BATCH_SIZE = 10;

exports.aurenFaostatScheduledIngest = onSchedule(
  {schedule:'every 6 hours', timeZone:'Africa/Khartoum', timeoutSeconds:540, memory:'512MiB'},
  async () => {
    const stateRef = db.collection('auren_ingest_state').doc('faostat');
    const stateSnap = await stateRef.get();
    const state = stateSnap.exists
      ? stateSnap.data()
      : {domainIndex:0,countryCursor:null};

    const domain = DOMAINS[Number(state.domainIndex || 0) % DOMAINS.length];

    let q = db.collection('auren_global_countries')
      .orderBy(admin.firestore.FieldPath.documentId())
      .limit(BATCH_SIZE);

    if (state.countryCursor) {
      q = db.collection('auren_global_countries')
        .orderBy(admin.firestore.FieldPath.documentId())
        .startAfter(state.countryCursor)
        .limit(BATCH_SIZE);
    }

    const snap = await q.get();

    if (snap.empty) {
      const nextDomain = (Number(state.domainIndex || 0) + 1) % DOMAINS.length;
      await stateRef.set({
        domainIndex:nextDomain,
        countryCursor:null,
        lastCycleCompletedAt:admin.firestore.FieldValue.serverTimestamp(),
        lastCompletedDomain:domain
      }, {merge:true});
      return null;
    }

    const callable = require('./faostat_bulk_ingest');
    let processed = 0;
    let failed = 0;

    for (const doc of snap.docs) {
      try {
        await callable.ingestFaostatCountryInternal(doc.id, domain, {
          pageSize:1000,
          maxPages:100
        });
        processed++;
      } catch (e) {
        failed++;
        await db.collection('auren_faostat_ingest_errors').doc(doc.id + '_' + domain)
          .set({
            iso3:doc.id,
            domain,
            error:String(e.message || e),
            updatedAt:admin.firestore.FieldValue.serverTimestamp()
          }, {merge:true});
      }
    }

    await stateRef.set({
      domainIndex:Number(state.domainIndex || 0),
      countryCursor:snap.docs[snap.docs.length - 1].id,
      lastRunAt:admin.firestore.FieldValue.serverTimestamp(),
      lastProcessed:processed,
      lastFailed:failed,
      lastDomain:domain
    }, {merge:true});

    return null;
  }
);
