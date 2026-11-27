PULSO - iPhone / iOS 26.0+

This artifact contains a real arm64 iPhone executable in Pulso-unsigned.ipa.
It is UNSIGNED and does not contain an Apple provisioning profile.

Before installing, sign it with your chosen authorized signing workflow.
The final application identity, signature and provisioning profile must agree.
The profile AND signed entitlements must permit:

  com.apple.developer.nfc.readersession.formats = ["TAG"]

NFC-entitlements.plist describes the required reader entitlement; the file by
itself does not grant it. A signing tool that removes NFC capabilities may
install the interface but the NFC reader will not work. Check the support of
your signing account/profile; do not assume every personal/free signing
method can preserve this capability.

This app uses ordinary Core NFC tag reading. It does not need or implement
Apple Pay, HCE, NFC & SE card emulation or SUBE authentication.

What this version does:
- Connects to tags exposed by iOS and reads public metadata.
- Shows NFC technology/family and the chip identifier when available.
- Keeps optional, deletable local scan history.
- Shares a diagnostic report, with the identifier hidden by default.

What this version cannot establish:
- An NFC detection does not prove that the card is a genuine SUBE.
- A chip UID is not the printed SUBE card number.
- Balance and last-trip data are not decoded without authentication.
- Some SUBE generations/modes may not be exposed by Core NFC at all.

To test: unlock the iPhone, open Pulso, start scanning and hold one card
against the upper back edge of the phone. Keep other NFC cards away.
If the tag is unsupported, a successful installation cannot add protocol
support that iOS does not provide.

BUILD INFO: build-info.json records the verified platform and deployment
target. SHA256SUMS.txt records the unsigned IPA hash. Re-signing changes it.

This build verifies compilation and packaging, not a physical SUBE scan.
