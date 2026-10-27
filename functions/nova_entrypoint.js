'use strict';

// Preserve all existing AUREN/NOVA functions, then register the free signal radar
// as Firebase callable/scheduled functions through the package entry point.
const functions = require('./index');
Object.assign(functions, require('./nova_signal_engine'));
Object.assign(functions, require('./nova_market_intelligence'));
module.exports = functions;
