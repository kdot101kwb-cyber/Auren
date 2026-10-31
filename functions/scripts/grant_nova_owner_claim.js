'use strict';

// Run manually with Firebase Admin Application Default Credentials.
// Never expose a service-account key or accept an owner UID from an untrusted client.
const {initializeApp, applicationDefault, getApps} = require('firebase-admin/app');
const {getAuth} = require('firebase-admin/auth');

async function main() {
  const uid = String(process.argv[2] || '').trim();
  if (!/^[A-Za-z0-9:_-]{1,128}$/.test(uid)) {
    throw new Error('Usage: node scripts/grant_nova_owner_claim.js <verified-firebase-uid>');
  }

  const projectId = process.env.GCLOUD_PROJECT || process.env.GOOGLE_CLOUD_PROJECT;
  if (!['auren-90ccc', 'auren-staging'].includes(projectId)) {
    throw new Error('Set GCLOUD_PROJECT explicitly to auren-90ccc or auren-staging.');
  }
  if (!getApps().length) initializeApp({credential:applicationDefault(), projectId});
  const auth = getAuth();
  const user = await auth.getUser(uid);
  const hasPasswordOrFederatedProvider = (user.providerData || [])
    .some((provider) => provider.providerId && provider.providerId !== 'anonymous');

  if (!user.email || user.emailVerified !== true || !hasPasswordOrFederatedProvider) {
    throw new Error('Refusing owner claim: account must have a verified email and a non-anonymous sign-in provider.');
  }

  await auth.setCustomUserClaims(uid, {
    ...(user.customClaims || {}),
    novaOwner:true,
  });

  process.stdout.write('NOVA owner claim granted to verified UID ' + uid + '. Refresh the user ID token in the app.\n');
}

main().catch((error) => {
  process.stderr.write(String(error.message || error) + '\n');
  process.exitCode = 1;
});
