#!/usr/bin/env bash
set -euo pipefail

# NOVA-only Android scaffold recovery.
# Run from any directory; all generated files stay inside nova_ai/.
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
NOVA_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

if [[ ! -f "${NOVA_ROOT}/pubspec.yaml" || ! -f "${NOVA_ROOT}/lib/main.dart" ]]; then
  echo "ERROR: expected NOVA Flutter project at ${NOVA_ROOT} (pubspec.yaml and lib/main.dart required)." >&2
  exit 2
fi

if [[ -f "${NOVA_ROOT}/android/app/build.gradle" || -f "${NOVA_ROOT}/android/app/build.gradle.kts" ]]; then
  echo "NOVA Android Gradle app file already exists; no scaffold changes made."
  exit 0
fi

if ! command -v flutter >/dev/null 2>&1; then
  echo "ERROR: Flutter SDK is required to generate NOVA's missing Android platform files." >&2
  exit 3
fi

echo "Android scaffold missing. Generating Android platform files inside NOVA only: ${NOVA_ROOT}"
cd "${NOVA_ROOT}"
flutter create --platforms=android --project-name nova_ai .
test -f "${NOVA_ROOT}/android/app/build.gradle" || test -f "${NOVA_ROOT}/android/app/build.gradle.kts"
echo "NOVA Android scaffold generated and verified."
