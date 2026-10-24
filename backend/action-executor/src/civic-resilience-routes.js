import crypto from 'node:crypto';
import {
  normalizeLegalCase,
  listUpcomingCaseDeadlines,
} from './legal-case-organizer.js';
import {
  normalizeWaterReading,
  calculateWaterConsumption,
} from './water-resource-tracker.js';
import {
  normalizeEnergyEntry,
  summarizeResourceUsage,
} from './energy-usage-analytics.js';
import {
  normalizeBiodiversityObservation,
  projectObservationForSharing,
} from './biodiversity-observations.js';

const MAX_LIST = 100;

function sendError(res, error) {
  const status = Number.isInteger(error?.code) && error.code >= 400 && error.code < 500
    ? error.code
    : 500;
  return res.status(status).json({ error: status === 500 ? 'Unable to process civic resilience request.' : error.message });
}

function safeId(value) {
  return typeof value === 'string' && value.trim() && value.length <= 128 && !value.includes('/')
    ? value.trim()
    : '';
}

function optionalId(value, field) {
  if (value == null || value === '') return null;
  const id = safeId(value);
  if (!id) throw Object.assign(new Error(`Invalid ${field}.`), { code: 400 });
  return id;
}

export function registerCivicResilienceRoutes(app, { db, requireUser, serverTimestamp }) {
  if (!app || !db || typeof requireUser !== 'function') {
    throw new TypeError('app, db, and requireUser are required.');
  }

  const userCollection = (uid, name) => db.collection('users').doc(uid).collection(name);

  app.get('/api/civic/legal-cases', requireUser, async (req, res) => {
    try {
      const snapshot = await userCollection(req.uid, 'legal_cases').orderBy('updatedAt', 'desc').limit(MAX_LIST).get();
      const cases = snapshot.docs.map((doc) => doc.data());
      const asOfDate = typeof req.query.asOfDate === 'string' ? req.query.asOfDate : new Date().toISOString().slice(0, 10);
      return res.json({
        cases,
        upcomingDeadlines: listUpcomingCaseDeadlines(cases, asOfDate, req.uid),
      });
    } catch (error) {
      return sendError(res, error);
    }
  });

  app.post('/api/civic/legal-cases', requireUser, async (req, res) => {
    try {
      const input = req.body?.case;
      const caseId = optionalId(input?.caseId, 'case id') || crypto.randomUUID();
      const item = normalizeLegalCase({ ...input, caseId }, req.uid);
      const saved = { ...item, updatedAt: new Date().toISOString() };
      await userCollection(req.uid, 'legal_cases').doc(caseId).set(saved, { merge: true });
      return res.status(201).json(saved);
    } catch (error) {
      return sendError(res, error);
    }
  });

  app.get('/api/civic/water/readings', requireUser, async (req, res) => {
    try {
      const rawMeterId = req.query.meterId;
      const meterId = rawMeterId == null || rawMeterId === '' ? '' : safeId(rawMeterId);
      if (rawMeterId != null && rawMeterId !== '' && !meterId) {
        throw Object.assign(new Error('Invalid meter id.'), { code: 400 });
      }
      let query = userCollection(req.uid, 'water_readings').orderBy('date', 'desc').limit(MAX_LIST);
      if (meterId) query = userCollection(req.uid, 'water_readings').where('meterId', '==', meterId).orderBy('date', 'desc').limit(MAX_LIST);
      const snapshot = await query.get();
      return res.json({ readings: snapshot.docs.map((doc) => doc.data()) });
    } catch (error) {
      return sendError(res, error);
    }
  });

  app.post('/api/civic/water/readings', requireUser, async (req, res) => {
    try {
      const item = normalizeWaterReading(req.body?.reading, req.uid);
      const ref = userCollection(req.uid, 'water_readings').doc(`${item.meterId}__${item.date}`);
      const existing = await ref.get();
      if (existing.exists && existing.data()?.unit !== item.unit) {
        throw Object.assign(new Error('A meter reading cannot change the meter unit.'), { code: 409 });
      }
      // Read one beyond the supported bound so we never validate monotonicity
      // against an incomplete, unordered sample of a meter's history.
      const meterSnapshot = await userCollection(req.uid, 'water_readings')
        .where('meterId', '==', item.meterId).limit(MAX_LIST + 1).get();
      if (meterSnapshot.size > MAX_LIST || meterSnapshot.docs.length > MAX_LIST) {
        throw Object.assign(
          new Error('This meter has more than 100 readings; its history must be reconciled before adding another reading.'),
          { code: 409 },
        );
      }
      const readings = meterSnapshot.docs.map((doc) => doc.data())
        .filter((reading) => reading.unit === item.unit && reading.date !== item.date)
        .sort((a, b) => a.date.localeCompare(b.date));
      const previous = readings.filter((reading) => reading.date < item.date).at(-1);
      const next = readings.find((reading) => reading.date > item.date);
      if (previous) calculateWaterConsumption(previous, item);
      if (next) calculateWaterConsumption(item, next);
      await ref.set(item, { merge: true });
      return res.status(201).json(item);
    } catch (error) {
      return sendError(res, error);
    }
  });

  app.get('/api/civic/resources/summary', requireUser, async (req, res) => {
    try {
      const from = typeof req.query.from === 'string' ? req.query.from : undefined;
      const to = typeof req.query.to === 'string' ? req.query.to : undefined;
      const snapshot = await userCollection(req.uid, 'resource_usage').limit(500).get();
      const entries = snapshot.docs.map((doc) => doc.data());
      return res.json({ summary: summarizeResourceUsage(entries, { from, to, ownerUid: req.uid }) });
    } catch (error) {
      return sendError(res, error);
    }
  });

  app.post('/api/civic/resources/entries', requireUser, async (req, res) => {
    try {
      const item = normalizeEnergyEntry(req.body?.entry, req.uid);
      const entryId = crypto.randomUUID();
      const saved = { ...item, entryId, ...(typeof serverTimestamp === 'function' ? { createdAt: serverTimestamp() } : {}) };
      await userCollection(req.uid, 'resource_usage').doc(entryId).set(saved);
      return res.status(201).json(saved);
    } catch (error) {
      return sendError(res, error);
    }
  });

  app.get('/api/civic/biodiversity/observations', requireUser, async (req, res) => {
    try {
      const snapshot = await userCollection(req.uid, 'biodiversity_observations').orderBy('observedOn', 'desc').limit(MAX_LIST).get();
      const observations = snapshot.docs.map((doc) => doc.data());
      return res.json({
        observations,
        shareable: observations.filter((item) => item.visibility === 'public').map(projectObservationForSharing),
      });
    } catch (error) {
      return sendError(res, error);
    }
  });

  app.post('/api/civic/biodiversity/observations', requireUser, async (req, res) => {
    try {
      const input = req.body?.observation;
      const observationId = optionalId(input?.observationId, 'observation id') || crypto.randomUUID();
      const item = normalizeBiodiversityObservation({ ...input, observationId }, req.uid);
      await userCollection(req.uid, 'biodiversity_observations').doc(observationId).set(item, { merge: true });
      return res.status(201).json({ observation: item, shareable: projectObservationForSharing(item) });
    } catch (error) {
      return sendError(res, error);
    }
  });
}
