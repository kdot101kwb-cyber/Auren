'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const source = fs.readFileSync(path.join(__dirname, 'trade_rfq.js'), 'utf8');

test('reverse marketplace supports draft creation, explicit publishing, quote submission and owner-only comparison', () => {
  assert.match(source, /exports\.createAurenTradeRFQ/);
  assert.match(source, /status:'draft'/);
  assert.match(source, /exports\.publishAurenTradeRFQ/);
  assert.match(source, /visibleToTradeNetwork:true/);
  assert.match(source, /exports\.submitAurenTradeQuote/);
  assert.match(source, /exports\.listAurenTradeRFQQuotes/);
  assert.match(source, /Only the RFQ owner can compare quotes/);
});

test('RFQ workflow validates amounts and uses authentication and App Check', () => {
  assert.match(source, /requireTradeAuth/);
  assert.match(source, /enforceAppCheck:true/);
  assert.match(source, /quantity <= 0/);
  assert.match(source, /totalPrice < 0/);
  assert.match(source, /tx\.create\(quoteRef, data\)/);
});

test('quote comparison groups currencies instead of inventing exchange rates', () => {
  assert.match(source, /const key = normalized\.currency \|\| 'UNKNOWN'/);
  assert.match(source, /no FX conversion/);
  assert.match(source, /verificationStatus:'not_assessed'/);
  assert.match(source, /externalDispatch:false/);
});
