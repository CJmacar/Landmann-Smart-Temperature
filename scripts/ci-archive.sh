#!/usr/bin/env bash
set -euo pipefail

PROJECT="Landmann Smart Temperature.xcodeproj"
SCHEME="Landmann Smart Temperature"
ARCHIVE_PATH="build/Landmann-Smart-Temperature.xcarchive"
EXPORT_PATH="build/export"
EXPORT_OPTIONS_PATH="${RUNNER_TEMP}/ExportOptions-ci.plist"

if [[ -z "${APPLE_TEAM_ID:-}" || -z "${PROVISIONING_PROFILE_NAME:-}" ]]; then
  echo "Missing APPLE_TEAM_ID or PROVISIONING_PROFILE_NAME secrets."
  exit 1
fi

mkdir -p "${EXPORT_PATH}"

/usr/libexec/PlistBuddy -c "Add :method string app-store-connect" "${EXPORT_OPTIONS_PATH}" 2>/dev/null || \
  /usr/libexec/PlistBuddy -c "Set :method app-store-connect" "${EXPORT_OPTIONS_PATH}"
/usr/libexec/PlistBuddy -c "Add :destination string export" "${EXPORT_OPTIONS_PATH}" 2>/dev/null || \
  /usr/libexec/PlistBuddy -c "Set :destination export" "${EXPORT_OPTIONS_PATH}"
/usr/libexec/PlistBuddy -c "Add :signingStyle string manual" "${EXPORT_OPTIONS_PATH}" 2>/dev/null || \
  /usr/libexec/PlistBuddy -c "Set :signingStyle manual" "${EXPORT_OPTIONS_PATH}"
/usr/libexec/PlistBuddy -c "Add :teamID string ${APPLE_TEAM_ID}" "${EXPORT_OPTIONS_PATH}" 2>/dev/null || \
  /usr/libexec/PlistBuddy -c "Set :teamID ${APPLE_TEAM_ID}" "${EXPORT_OPTIONS_PATH}"
/usr/libexec/PlistBuddy -c "Add :uploadSymbols bool true" "${EXPORT_OPTIONS_PATH}" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :provisioningProfiles dict" "${EXPORT_OPTIONS_PATH}" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :provisioningProfiles:Island-Creatives.Landmann-Smart-Temperature string ${PROVISIONING_PROFILE_NAME}" "${EXPORT_OPTIONS_PATH}" 2>/dev/null || \
  /usr/libexec/PlistBuddy -c "Set :provisioningProfiles:Island-Creatives.Landmann-Smart-Temperature ${PROVISIONING_PROFILE_NAME}" "${EXPORT_OPTIONS_PATH}"

echo "Archiving ${SCHEME}..."
xcodebuild \
  -project "${PROJECT}" \
  -scheme "${SCHEME}" \
  -configuration Release \
  -destination "generic/platform=iOS" \
  -archivePath "${ARCHIVE_PATH}" \
  DEVELOPMENT_TEAM="${APPLE_TEAM_ID}" \
  CODE_SIGN_STYLE=Manual \
  CODE_SIGN_IDENTITY="Apple Distribution" \
  PROVISIONING_PROFILE_SPECIFIER="${PROVISIONING_PROFILE_NAME}" \
  archive

echo "Exporting IPA..."
xcodebuild \
  -exportArchive \
  -archivePath "${ARCHIVE_PATH}" \
  -exportPath "${EXPORT_PATH}" \
  -exportOptionsPlist "${EXPORT_OPTIONS_PATH}"

echo "IPA created in ${EXPORT_PATH}"
