import test from 'node:test';
import assert from 'node:assert/strict';
import { normalizeLegalCase, listUpcomingCaseDeadlines } from './legal-case-organizer.js';
import { normalizeWaterReading, calculateWaterConsumption } from './water-resource-tracker.js';
import { normalizeEnergyEntry, summarizeResourceUsage } from './energy-usage-analytics.js';
import { normalizeBiodiversityObservation, projectObservationForSharing } from './biodiversity-observations.js';

test('legal case organizer validates dates, bounds text, and sorts opted-in reminders', () => {
  const item = normalizeLegalCase({
    caseId: 'case-1', title: 'Lease review', status: 'active', createdDate: '2026-01-01',
    nextDeadline: '2026-11-01', reminderEnabled: true,
  }, 'owner-1');
  assert.equal(item.ownerUid, 'owner-1');
  assert.equal(item.status, 'active');
  assert.equal(listUpcomingCaseDeadlines([item], '2026-10-23').length, 1);
  assert.equal(listUpcomingCaseDeadlines([{ ...item, reminderEnabled: false }], '2026-10-23').length, 0);
  assert.throws(() => normalizeLegalCase({ title: 'Bad date', createdDate: '2026-02-30' }, 'owner-1'), /createdDate/i);
  assert.throws(() => normalizeLegalCase({ title: 'Bad order', createdDate: '2026-02-10', nextDeadline: '2026-02-01' }, 'owner-1'), /precede/i);
  assert.throws(() => normalizeLegalCase({ title: 'x'.repeat(161) }, 'owner-1'), /title/i);
  assert.deepEqual(
    listUpcomingCaseDeadlines([
      { ...item, nextDeadline: 'not-a-date' },
      { ...item, status: 'closed', nextDeadline: '2026-10-24' },
      { ...item, nextDeadline: '2026-10-23' },
    ], '2026-10-23').map((entry) => entry.nextDeadline),
    ['2026-10-23'],
  );
});

test('water resource tracker rejects decreasing meters and calculates consumption safely', () => {
  const previous = normalizeWaterReading({ meterId: 'meter-1', date: '2026-01-01', value: 100, unit: 'litre' }, 'owner-1');
  const current = normalizeWaterReading({ meterId: 'meter-1', date: '2026-01-10', value: 145, unit: 'litre' }, 'owner-1');
  assert.equal(calculateWaterConsumption(previous, current).consumed, 45);
  assert.throws(() => calculateWaterConsumption(previous, { ...current, value: 99 }), /monotonic/i);
  assert.throws(() => normalizeWaterReading({ meterId: 'meter-1', date: '2026-01-01', value: -1, unit: 'litre' }, 'owner-1'), /non-negative/i);
  assert.throws(() => normalizeWaterReading({ meterId: 'meter-1', date: '2026-01-01', value: 1, unit: 'unknown' }, 'owner-1'), /unit/i);
  assert.throws(() => calculateWaterConsumption(previous, { ...current, date: 'not-a-date' }), /date/i);
  assert.throws(() => calculateWaterConsumption(previous, { ...current, ownerUid: 'owner-2' }), /owner/i);
});

test('energy analytics aggregates only valid entries by matching units and date range', () => {
  const entries = [
    normalizeEnergyEntry({ label: 'Home meter', date: '2026-01-01', unit: 'kwh', amount: 12, costMinor: 250 }, 'owner-1'),
    normalizeEnergyEntry({ label: 'Home meter', date: '2026-01-02', unit: 'kwh', amount: 8, costMinor: 150 }, 'owner-1'),
    normalizeEnergyEntry({ label: 'Generator fuel', date: '2026-01-02', unit: 'litre', amount: 4 }, 'owner-1'),
  ];
  const result = summarizeResourceUsage(entries, { from: '2026-01-02', to: '2026-01-31', ownerUid: 'owner-1' });
  assert.deepEqual(result, [
    { unit: 'kwh', amount: 8, costMinor: 150, costEntries: 1, entries: 1 },
    { unit: 'litre', amount: 4, costMinor: 0, costEntries: 0, entries: 1 },
  ]);
  assert.throws(() => normalizeEnergyEntry({ label: 'bad', date: '2026-01-01', unit: 'kwh', amount: -2 }, 'owner-1'), /amount/i);
  assert.throws(() => summarizeResourceUsage(entries, { from: '2026-02-01', to: '2026-01-01', ownerUid: 'owner-1' }), /range/i);
  assert.throws(() => summarizeResourceUsage(entries, { from: '2026-01-01', to: '2026-01-31' }), /owner uid/i);
  const mixedOwners = [...entries, normalizeEnergyEntry({ label: 'Other user meter', date: '2026-01-02', unit: 'kwh', amount: 999 }, 'owner-2')];
  assert.deepEqual(summarizeResourceUsage(mixedOwners, { from: '2026-01-01', to: '2026-01-31', ownerUid: 'owner-1' }), [
    { unit: 'kwh', amount: 20, costMinor: 400, costEntries: 2, entries: 2 },
    { unit: 'litre', amount: 4, costMinor: 0, costEntries: 0, entries: 1 },
  ]);
});

test('biodiversity sharing projection does not expose owner or exact coordinates', () => {
  const observation = normalizeBiodiversityObservation({
    observationId: 'obs-1', species: 'Acacia', observedOn: '2026-03-01',
    latitude: 15.5, longitude: 32.5, visibility: 'public',
  }, 'owner-secret');
  const shared = projectObservationForSharing(observation);
  assert.equal(shared.species, 'Acacia');
  assert.equal(shared.locationAvailable, true);
  assert.equal('ownerUid' in shared, false);
  assert.equal('latitude' in shared, false);
  assert.equal('longitude' in shared, false);
  assert.throws(() => normalizeBiodiversityObservation({
    species: 'Tree', observedOn: '2026-02-30', latitude: 10,
  }, 'owner-1'), /date/i);
  assert.throws(() => normalizeBiodiversityObservation({
    species: 'Tree', observedOn: '2026-01-01', latitude: 91, longitude: 10,
  }, 'owner-1'), /Coordinates/i);
  assert.throws(() => normalizeBiodiversityObservation({
    species: 'Tree', observedOn: '2026-01-01', latitude: 10,
  }, 'owner-1'), /supplied together/i);
  const privateObservation = normalizeBiodiversityObservation({
    species: 'Private tree', observedOn: '2026-01-01', latitude: 10, longitude: 20,
  }, 'owner-1');
  assert.equal(projectObservationForSharing(privateObservation).locationAvailable, undefined);
});
