# Firebase setup for AUREN

AUREN now has Firebase Core, Authentication and Cloud Firestore dependencies.

## One-time setup

From the Flutter project directory:

1. Install Firebase CLI and log in.
2. Install FlutterFire CLI.
3. Run `flutterfire configure`.
4. Select the AUREN Firebase project and Android platform.
5. Enable **Anonymous** sign-in in Firebase Authentication.
6. Create a Cloud Firestore database.
7. Deploy Firestore security rules before production use.

FlutterFire generates `lib/firebase_options.dart`; this file contains app configuration identifiers and is not a place for server secrets.

## Initialize Firebase

After `flutterfire configure`, initialize Firebase before `runApp`:

```dart
WidgetsFlutterBinding.ensureInitialized();
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
runApp(const AurenApp());
```

## Data model

```
users/{uid}
conversations/{conversationId}
conversations/{conversationId}/messages/{messageId}
```

Message fields:

- senderId
- text
- createdAt
- isAi

## Security direction

Users should only read/write conversations they are members of. AI provider credentials must stay on the trusted AUREN backend, never in Flutter.

The production security rules will be added after the conversation membership model is finalized.
