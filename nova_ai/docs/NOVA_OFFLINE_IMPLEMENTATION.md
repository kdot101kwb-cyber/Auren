# NOVA offline foundation: tasks and income plans

This change introduces a small local persistence service for task records and income-planning scenarios.

## Included
- Save, update, load, and delete lightweight tasks.
- Save, update, load, and delete income plans.
- Calculate estimated monthly profit and break-even months.
- Unit tests for persistence and calculations.

## Important limits
- Records are stored in Android app preferences through `shared_preferences`; this is suitable for small records, not large databases, files, or model weights.
- Profit and break-even are estimates based on user-entered assumptions. They are not guaranteed earnings or investment advice.
- Fresh global opportunities, market prices, and exchange rates require a network connection. When offline, NOVA should label cached market data with its last-updated timestamp.
- This foundation does not yet integrate these records into the dashboard UI and is not a local language-model runtime.

## Validation
Run from `nova_ai/`:
```sh
flutter pub get
dart format lib/services/offline/nova_offline_store.dart test/services/offline/nova_offline_store_test.dart
flutter analyze
flutter test test/services/offline/nova_offline_store_test.dart
flutter build apk --debug
```

## Offline startup follow-up
Review `lib/main.dart` and `lib/firebase_runtime.dart` so a Firebase/network initialization failure cannot prevent access to local-only tools. Keep cloud-dependent features disabled with a clear status when offline; do not silently claim cloud work ran.
