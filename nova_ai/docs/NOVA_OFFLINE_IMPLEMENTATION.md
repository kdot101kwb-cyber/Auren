# NOVA offline storage and income planning

This change introduces a small device-local store for tasks and income plans.

## Included
- Save, list, update, and delete offline tasks.
- Save, list, update, and delete income plans.
- Calculate estimated monthly profit and simple break-even months.
- Keep these operations independent of Firebase and internet connectivity.
- Unit tests using Flutter's SharedPreferences mock.

## Limits and follow-up
- SharedPreferences is appropriate for small records, not large files or secrets.
- Break-even is a simple estimate based on the entered monthly figures; it is not a promise of earnings.
- Global opportunities, current prices, account recovery, cloud AI, and publishing require their respective network services and permissions.
- This patch does not yet add an on-device language model or change the dashboard UI to expose these records. Those are separate implementation steps.
- Firebase initialization already catches its own errors in `firebase_runtime.dart`; verify offline launch on a real device as part of integration testing.

## Verify from `nova_ai/`
```sh
flutter pub get
dart format lib/services/offline/nova_offline_store.dart test/services/offline/nova_offline_store_test.dart
flutter analyze
flutter test test/services/offline/nova_offline_store_test.dart
flutter test
flutter build apk --debug
```
