#!/usr/bin/env bash
set -euo pipefail

PROJECT="Landmann Smart Temperature.xcodeproj"
SCHEME="Landmann Smart Temperature"
ARCHIVE_PATH="${1:-build/Landmann-Smart-Temperature.xcarchive}"
EXPORT_PATH="${2:-build/export}"

echo "Archiving ${SCHEME}..."
xcodebuild \
  -project "${PROJECT}" \
  -scheme "${SCHEME}" \
  -configuration Release \
  -destination "generic/platform=iOS" \
  -archivePath "${ARCHIVE_PATH}" \
  archive

echo "Exporting App Store package..."
xcodebuild \
  -exportArchive \
  -archivePath "${ARCHIVE_PATH}" \
  -exportPath "${EXPORT_PATH}" \
  -exportOptionsPlist ExportOptions.plist

echo "Done. Upload ${EXPORT_PATH}/*.ipa with Transporter or Xcode Organizer."
