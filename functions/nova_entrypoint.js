'use strict';

// Preserve all existing AUREN/NOVA functions and register NOVA engines.
const functions = require('./index');
Object.assign(functions, require('./nova_signal_engine'));
Object.assign(functions, require('./nova_revenue_engine'));
// Export the NOVA task center callables and milestone push trigger so Firebase
// deploys them from the package entrypoint.
Object.assign(functions, require('./nova_command_center'));
module.exports = functions;
