'use strict';

// Run manually with Firebase Admin Application Default Credentials.
// Never expose a service-account key or accept an owner UID from an untrusted client.
const {initializeApp, applicationDefault, getApps} = require('firebase-admin/app');
const {getAuth} = require('firebase-admin/auth');

function validateNovaOwnerGrantTarget(uid, expectedEmail, projectId, user) {
  if (!/^[A-Za-z0-9:_-]{1,128}$/.test(String(uid || '')) ||
      !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(String(expectedEmail || ''))) {
    throw new Error('A valid Firebase UID and expected owner email are required.');
  }
  if (!['auren-90ccc', 'auren-staging'].includes(projectId)) {
    throw new Error('Set GCLOUD_PROJECT explicitly to auren-90ccc or auren-staging.');
  }
  const hasPasswordOrFederatedProvider = (user?.providerData || [])
    .some((provider) => provider.providerId && provider.providerId !== 'anonymous');
  if (!user?.email || user.email.toLowerCase() !== expectedEmail ||
      user.emailVerified !== true || !hasPasswordOrFederatedProvider) {
    throw new Error('Refusing owner claim: UID and expected email must match a verified, non-anonymous account.');
  }
}

async function main() {
  const uid = String(process.argv[2] || '').trim();
  const expectedEmail = String(process.argv[3] || '').trim().toLowerCase();
  const projectId = process.env.GCLOUD_PROJECT || process.env.GOOGLE_CLOUD_PROJECT;
  if (!/^[A-Za-z0-9:_-]{1,128}$/.test(uid) || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(expectedEmail)) {
    throw new Error('Usage: node scripts/grant_nova_owner_claim.js <verified-firebase-uid> <expected-owner-email>');
  }
  if (!['auren-90ccc', 'auren-staging'].includes(projectId)) {
    throw new Error('Set GCLOUD_PROJECT explicitly to auren-90ccc or auren-staging.');
  }
  if (!getApps().length) initializeApp({credential:applicationDefault(), projectId});
  const auth = getAuth();
  const user = await auth.getUser(uid);
  validateNovaOwnerGrantTarget(uid, expectedEmail, projectId, user);

  await auth.setCustomUserClaims(uid, {
    ...(user.customClaims || {}),
    novaOwner:true,
  });

  process.stdout.write('NOVA owner claim granted to verified UID ' + uid + '. Refresh the user ID token in the app.\n');
}

if (require.main === module) {
  main().catch((error) => {
    process.stderr.write(String(error.message || error) + '\n');
    process.exitCode = 1;
  });
}

module.exports = {validateNovaOwnerGrantTarget};
