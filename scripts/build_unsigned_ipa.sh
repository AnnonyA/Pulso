#!/usr/bin/env bash
set -euo pipefail

pulso_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$pulso_root"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "ERROR: An iPhone IPA requires macOS with Xcode. Run the GitHub Actions workflow from Windows." >&2
  exit 1
fi
if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "ERROR: Xcode is not installed or selected." >&2
  exit 1
fi

python3 scripts/validate_project.py
pulso_xcode_version="$(xcodebuild -version | head -n 1 | awk '{print $2}')"
pulso_sdk_version="$(xcrun --sdk iphoneos --show-sdk-version)"
if (( ${pulso_xcode_version%%.*} < 26 || ${pulso_sdk_version%%.*} < 26 )); then
  echo "ERROR: Xcode 26+ and an iPhoneOS SDK 26+ are required. Selected Xcode: $pulso_xcode_version; SDK: $pulso_sdk_version" >&2
  exit 1
fi

# All cleaned paths are fixed, project-local generated directories.
mkdir -p build dist
rm -rf build/Payload build/PulsoBuild.xcresult
rm -f dist/Pulso-unsigned.ipa dist/build-info.json dist/SHA256SUMS.txt

xcodebuild \
  -project Pulso.xcodeproj \
  -scheme Pulso \
  -configuration Release \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  -derivedDataPath build/DerivedData \
  -resultBundlePath build/PulsoBuild.xcresult \
  IPHONEOS_DEPLOYMENT_TARGET=26.0 \
  ARCHS=arm64 \
  ONLY_ACTIVE_ARCH=NO \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY= \
  DEVELOPMENT_TEAM= \
  PROVISIONING_PROFILE_SPECIFIER= \
  build 2>&1 | tee build/xcodebuild.log

pulso_app="build/DerivedData/Build/Products/Release-iphoneos/Pulso.app"
if [[ ! -f "$pulso_app/Pulso" ]]; then
  echo "ERROR: Xcode did not produce the iPhone executable." >&2
  exit 1
fi

mkdir -p build/Payload
/usr/bin/ditto "$pulso_app" build/Payload/Pulso.app
(
  cd build
  COPYFILE_DISABLE=1 /usr/bin/zip -q -r -X ../dist/Pulso-unsigned.ipa Payload
)

python3 scripts/verify_ipa.py dist/Pulso-unsigned.ipa --output dist/build-info.json
cp Config/Pulso.entitlements dist/NFC-entitlements.plist
cp docs/INSTALL_README.txt dist/INSTALL_README.txt
(
  cd dist
  shasum -a 256 Pulso-unsigned.ipa > SHA256SUMS.txt
)

echo "Built and verified: $pulso_root/dist/Pulso-unsigned.ipa"
echo "This file is unsigned. Installation and NFC require a valid signature/provisioning profile with TAG reader entitlement."
