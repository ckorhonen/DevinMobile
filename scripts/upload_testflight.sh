#!/bin/bash
set -euo pipefail

IPA_PATH="${1:-/tmp/DevinMobileExport/DevinMobile.ipa}"
API_KEY_ID="W7NR255577"
API_ISSUER_ID="69a6de97-aa61-47e3-e053-5b8c7c11a4d1"

echo "Uploading $IPA_PATH to App Store Connect..."

xcrun altool --upload-app \
  -f "$IPA_PATH" \
  -t ios \
  --apiKey "$API_KEY_ID" \
  --apiIssuer "$API_ISSUER_ID"

echo "Upload complete. Check App Store Connect for build processing status."
echo "Run: asc testflight builds list --app com.sourcebottle.devin-mobile"
