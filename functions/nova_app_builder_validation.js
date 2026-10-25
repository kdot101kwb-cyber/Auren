'use strict';
const {HttpsError} = require('firebase-functions/v2/https');
const TYPES = new Set(['flutter_app', 'web_app', 'landing_page', 'debug_existing', 'redesign_existing']);
const STACKS = new Set(['flutter', 'web', 'static_web', 'auto']);
function validateBuildRequest(data) {
  const type = String(data?.type || '');
  const prompt = typeof data?.prompt === 'string' ? data.prompt.trim() : '';
  const stack = String(data?.stack || 'auto');
  if (!TYPES.has(type)) throw new HttpsError('invalid-argument', 'Unsupported build task type.');
  if (prompt.length < 12 || prompt.length > 12000) throw new HttpsError('invalid-argument', 'Describe the project in 12–12000 characters.');
  if (!STACKS.has(stack)) throw new HttpsError('invalid-argument', 'Unsupported technology stack.');
  return {type, prompt, stack};
}
module.exports = {validateBuildRequest, TYPES, STACKS};
