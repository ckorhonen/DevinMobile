#!/bin/bash
set -euo pipefail

# Source credentials from .env
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/../.env"

if [ ! -f "$ENV_FILE" ]; then
  echo "Error: .env file not found. Copy .env.example to .env and fill in your credentials."
  exit 1
fi

source "$ENV_FILE"

IPA_PATH="${1:-/tmp/DevinMobileExport/DevinMobile.ipa}"
API_KEY_ID="${APP_STORE_KEY_ID}"
API_ISSUER_ID="${APP_STORE_ISSUER_ID}"

echo "Uploading $IPA_PATH to App Store Connect..."

xcrun altool --upload-app \
  -f "$IPA_PATH" \
  -t ios \
  --apiKey "$API_KEY_ID" \
  --apiIssuer "$API_ISSUER_ID"

echo "Upload complete. Check App Store Connect for build processing status."
echo "Run: asc testflight builds list --app com.sourcebottle.devin-mobile"
