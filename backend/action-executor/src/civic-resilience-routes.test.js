import test from 'node:test';
import assert from 'node:assert/strict';
import { registerCivicResilienceRoutes } from './civic-resilience-routes.js';

function harness() {
  const routes = new Map();
  const writes = [];
  const db = {
    collection(name) {
      assert.equal(name, 'users');
      return {
        doc(uid) {
          return {
            collection(collectionName) {
              return {
                doc(id) {
                  return {
                    async set(value, options) {
                      writes.push({ uid, collectionName, id, value, options });
                    },
                  };
                },
              };
            },
          };
        },
      };
    },
  };
  const app = {
    get(path, ...handlers) { routes.set(`GET ${path}`, handlers); },
    post(path, ...handlers) { routes.set(`POST ${path}`, handlers); },
  };
  const requireUser = (_req, _res, next) => next();
  registerCivicResilienceRoutes(app, { db, requireUser });
  return { routes, writes };
}

function response() {
  return {
    statusCode: 200,
    body: undefined,
    status(code) { this.statusCode = code; return this; },
    json(value) { this.body = value; return this; },
  };
}

test('civic resilience APIs are mounted behind authentication', () => {
  const { routes } = harness();
  assert.equal(routes.size, 8);
  for (const [path, handlers] of routes) {
    assert.equal(typeof handlers[0], 'function', `${path} must require authentication`);
    assert.equal(typeof handlers[1], 'function', `${path} must have a handler`);
  }
});

test('legal case creation derives owner from authenticated request and validates dates', async () => {
  const { routes, writes } = harness();
  const handlers = routes.get('POST /api/civic/legal-cases');
  const res = response();
  await handlers[1]({ uid: 'trusted-user', body: { case: {
    title: 'Lease review', status: 'active', createdDate: '2026-01-01',
    nextDeadline: '2026-11-01', ownerUid: 'attacker',
  } } }, res);
  assert.equal(res.statusCode, 201);
  assert.equal(writes.length, 1);
  assert.equal(writes[0].uid, 'trusted-user');
  assert.equal(writes[0].collectionName, 'legal_cases');
  assert.equal(writes[0].value.ownerUid, 'trusted-user');
  assert.notEqual(writes[0].value.ownerUid, 'attacker');
});

test('biodiversity create returns a privacy-safe sharing projection', async () => {
  const { routes, writes } = harness();
  const handlers = routes.get('POST /api/civic/biodiversity/observations');
  const res = response();
  await handlers[1]({ uid: 'trusted-user', body: { observation: {
    species: 'Acacia', observedOn: '2026-03-01', latitude: 15.5, longitude: 32.5, visibility: 'public',
  } } }, res);
  assert.equal(res.statusCode, 201);
  assert.equal(writes[0].collectionName, 'biodiversity_observations');
  assert.equal(writes[0].value.ownerUid, 'trusted-user');
  assert.equal(res.body.shareable.locationAvailable, true);
  assert.equal('ownerUid' in res.body.shareable, false);
  assert.equal('latitude' in res.body.shareable, false);
  assert.equal('longitude' in res.body.shareable, false);
});

test('invalid legal case dates fail without persisting a record', async () => {
  const { routes, writes } = harness();
  const handlers = routes.get('POST /api/civic/legal-cases');
  const res = response();
  await handlers[1]({ uid: 'trusted-user', body: { case: {
    title: 'Invalid date', createdDate: '2026-02-30',
  } } }, res);
  assert.equal(res.statusCode, 400);
  assert.equal(writes.length, 0);
});
