# Profile public-projection backfill

This script migrates legacy `users/{uid}/profile_modes/{mode}` documents into the allowlisted `public_profile_modes` projection used by public profile rendering and discovery.

## Safety

- Dry-run is the default; it does not write to Firestore.
- Review the reported counts and take a suitable backup before using `--apply`.
- Run only with an explicitly authorized Firebase Admin credential and an explicit `--project` value; the script checks the initialized Firebase project before proceeding.
- The script does not delete private source documents. For modes where `discoverable` is not exactly `true`, it deletes only the corresponding public projection.
- The script never copies the private `links` field into the public projection.
- This is an operational migration, not an automatic CI or deployment step.

## Run

From the `functions` directory, configure Application Default Credentials, then pass the intended Firebase project explicitly. The script refuses to infer a project from local defaults:

```sh
node migrate_public_profile_modes.js --project auren-staging
```

Only after reviewing the dry-run counts and confirming the target project, execute:

```sh
node migrate_public_profile_modes.js --project auren-staging --apply
```

Do not run this against production until the PR is reviewed, emulator tests pass, and a rollback plan is ready.
