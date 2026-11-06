'use strict';

// Preserve all existing AUREN/NOVA functions and register NOVA engines.
const functions = require('./index');
Object.assign(functions, require('./nova_signal_engine'));
Object.assign(functions, require('./nova_revenue_engine'));
// Export the NOVA task center callables, background workers, and milestone
// push trigger so Firebase deploys the complete task lifecycle.
Object.assign(functions, require('./nova_command_center'));
Object.assign(functions, require('./nova_task_worker'));
module.exports = functions;
