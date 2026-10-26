'use strict';

// Preserve all existing AUREN/NOVA functions and register NOVA engines.
const functions = require('./index');
Object.assign(functions, require('./nova_signal_engine'));
Object.assign(functions, require('./nova_revenue_engine'));
module.exports = functions;
