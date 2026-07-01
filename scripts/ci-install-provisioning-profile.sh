#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${PROVISIONING_PROFILE_BASE64:-}" ]]; then
  echo "Missing signing secret: PROVISIONING_PROFILE_BASE64"
  exit 1
fi

PROFILE_PATH="${RUNNER_TEMP}/Landmann.mobileprovision"
mkdir -p "${HOME}/Library/MobileDevice/Provisioning Profiles"

echo "${PROVISIONING_PROFILE_BASE64}" | base64 --decode > "${PROFILE_PATH}"
cp "${PROFILE_PATH}" "${HOME}/Library/MobileDevice/Provisioning Profiles/"

echo "Provisioning profile installed."
