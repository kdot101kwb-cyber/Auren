#!/usr/bin/env bash
set -euo pipefail

# NOVA-only Android scaffold recovery. Never run this from AUREN's root.
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
NOVA_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

if [[ ! -f "${NOVA_ROOT}/pubspec.yaml" || ! -f "${NOVA_ROOT}/lib/main.dart" ]]; then
  echo "ERROR: NOVA project files were not found at ${NOVA_ROOT}." >&2
  exit 2
fi

if [[ -f "${NOVA_ROOT}/android/app/build.gradle" || -f "${NOVA_ROOT}/android/app/build.gradle.kts" ]]; then
  echo "NOVA Android app Gradle file already exists; no scaffold changes made."
  exit 0
fi

if ! command -v flutter >/dev/null 2>&1; then
  echo "ERROR: Flutter SDK is required; no files were changed." >&2
  exit 3
fi

cd "${NOVA_ROOT}"
echo "Generating Android platform files inside NOVA only: ${NOVA_ROOT}"
flutter create --platforms=android --project-name nova_ai .
if [[ ! -f "${NOVA_ROOT}/android/app/build.gradle" && ! -f "${NOVA_ROOT}/android/app/build.gradle.kts" ]]; then
  echo "ERROR: Flutter finished without creating an app Gradle file." >&2
  exit 4
fi
echo "NOVA Android scaffold exists. Build and test are still required."
