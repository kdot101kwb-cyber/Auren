'use strict';

const {initializeApp, applicationDefault, getApps, getApp} = require('firebase-admin/app');
const {getAuth} = require('firebase-admin/auth');

const ALLOWED_PROJECTS = ['auren-90ccc', 'auren-staging'];
const UID_PATTERN = /^[A-Za-z0-9:_-]{1,128}$/;
const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

function validateNovaOwnerGrantArguments(uid, expectedEmail, projectId) {
  if (!UID_PATTERN.test(String(uid || '')) ||
      !EMAIL_PATTERN.test(String(expectedEmail || ''))) {
    throw new Error('A valid Firebase UID and expected owner email are required.');
  }
  if (!ALLOWED_PROJECTS.includes(projectId)) {
    throw new Error('Set GCLOUD_PROJECT explicitly to auren-90ccc or auren-staging.');
  }
}

function validateNovaOwnerAdminApp(projectId, appProjectId) {
  if (!ALLOWED_PROJECTS.includes(projectId) || appProjectId !== projectId) {
    throw new Error('Refusing owner claim: the initialized Firebase Admin app must target the explicitly selected project.');
  }
}

function validateNovaOwnerGrantTarget(uid, expectedEmail, projectId, user) {
  validateNovaOwnerGrantArguments(uid, expectedEmail, projectId);
  const hasPasswordOrFederatedProvider = (user?.providerData || [])
    .some((provider) => provider.providerId && provider.providerId !== 'anonymous');
  if (!user?.email || user.email.toLowerCase() !== expectedEmail.toLowerCase() ||
      user.emailVerified !== true || !hasPasswordOrFederatedProvider) {
    throw new Error('Refusing owner claim: UID and expected email must match a verified, non-anonymous account.');
  }
}

async function grantNovaOwnerClaim(auth, uid, expectedEmail, projectId) {
  validateNovaOwnerGrantArguments(uid, expectedEmail, projectId);
  if (!auth || typeof auth.getUser !== 'function' ||
      typeof auth.setCustomUserClaims !== 'function') {
    throw new Error('A Firebase Admin Auth client is required.');
  }

  const user = await auth.getUser(uid);
  validateNovaOwnerGrantTarget(uid, expectedEmail, projectId, user);
  const nextClaims = {
    ...(user.customClaims || {}),
    novaOwner:true,
  };
  await auth.setCustomUserClaims(uid, nextClaims);
  return {uid, customClaims:nextClaims};
}

async function main() {
  const uid = String(process.argv[2] || '').trim();
  const expectedEmail = String(process.argv[3] || '').trim().toLowerCase();
  const projectId = process.env.GCLOUD_PROJECT || process.env.GOOGLE_CLOUD_PROJECT;
  validateNovaOwnerGrantArguments(uid, expectedEmail, projectId);

  const app = getApps().length
    ? getApp()
    : initializeApp({credential:applicationDefault(), projectId});
  validateNovaOwnerAdminApp(projectId, app.options.projectId);
  const result = await grantNovaOwnerClaim(getAuth(app), uid, expectedEmail, projectId);
  process.stdout.write('NOVA owner claim granted to verified UID ' + result.uid + '. Refresh the user ID token in the app.\n');
}

if (require.main === module) {
  main().catch((error) => {
    process.stderr.write(String(error.message || error) + '\n');
    process.exitCode = 1;
  });
}

module.exports = {
  validateNovaOwnerGrantArguments,
  validateNovaOwnerAdminApp,
  validateNovaOwnerGrantTarget,
  grantNovaOwnerClaim,
};
