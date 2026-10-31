'use strict';

const {HttpsError} = require('firebase-functions/v2/https');

function requireNovaOwner(request) {
  const auth = request?.auth;
  if (!auth?.uid) {
    throw new HttpsError('unauthenticated', 'Sign in to access the private NOVA workspace.');
  }

  const token = auth.token || {};
  const provider = token.firebase?.sign_in_provider;
  if (token.novaOwner !== true || token.email_verified !== true || provider === 'anonymous') {
    throw new HttpsError(
      'permission-denied',
      'This private NOVA workspace is restricted to its verified owner account.',
    );
  }

  return auth.uid;
}

module.exports = {requireNovaOwner};
