# NOVA owner identity setup

NOVA task submission, task management, and self-repair callables require a verified Firebase account carrying the server-issued `novaOwner: true` custom claim. An anonymous account or an ordinary signed-in account is not sufficient.

## Preserve the existing account

Before starting, enable the **Email/Password** provider in Firebase Authentication for the intended project. Do not change or disable the current anonymous provider while linking the existing account.

1. Open NOVA's Task Center on the device that currently owns the NOVA data.
2. In **حماية حساب مالك NOVA**, enter an email and a new password, then choose **ربط البريد بالحساب الحالي**.
3. Firebase links the credential to the existing anonymous Firebase user. This preserves its UID and its existing `users/{uid}` Firestore data.
4. Open the verification email and verify the address.
5. Return to NOVA and choose **تحديث صلاحية المالك**. The screen shows the current UID and whether the owner claim is present.

If Firebase reports that the email is already in use, stop. Do not sign out or create a replacement account: that would not automatically transfer the existing UID's data.

## Grant the owner claim (one-time administrator operation)

Only a trusted Firebase project administrator should run this after verifying the email and confirming the UID belongs to the device owner. Do not expose service-account credentials in the repository, app, or chat.

With Firebase Admin Application Default Credentials configured for the intended project:

```bash
cd functions
GCLOUD_PROJECT=auren-90ccc node scripts/grant_nova_owner_claim.js <verified-firebase-uid>
```

For staging, explicitly use `GCLOUD_PROJECT=auren-staging`. The script refuses anonymous or unverified accounts and preserves existing custom claims.

After the claim is granted, return to NOVA and choose **تحديث صلاحية المالك** to force-refresh the Firebase ID token. The server still checks the claim, verified email, and non-anonymous provider on every protected callable.

## Security notes

- The app never grants its own owner claim.
- Linking a credential does not move or copy Firestore data and preserves the current UID.
- If the email is already attached to another Firebase account, account migration requires a separate reviewed procedure; do not merge accounts automatically.
- App Check remains an additional app-attestation layer, not a substitute for owner authorization.
- Never paste passwords, ID tokens, service-account JSON, or GitHub tokens into support chats or repository files.
