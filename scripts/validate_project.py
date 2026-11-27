#!/usr/bin/env python3
"""Portable packaging/configuration checks. This is not a Swift compiler."""
from __future__ import annotations
import json
from pathlib import Path
import plistlib
import re
import struct
import sys
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def read_plist(relative: str) -> dict:
    with (ROOT / relative).open("rb") as handle:
        return plistlib.load(handle)


def main() -> int:
    info = read_plist("Config/Info.plist")
    entitlements = read_plist("Config/Pulso.entitlements")
    privacy = read_plist("Sources/Pulso/Resources/PrivacyInfo.xcprivacy")
    require(bool(info.get("NFCReaderUsageDescription", "").strip()), "NFC usage description is missing.")
    require("arm64" in info.get("UIRequiredDeviceCapabilities", []), "arm64 capability is missing.")
    require(entitlements.get("com.apple.developer.nfc.readersession.formats") == ["TAG"], "Only the TAG reader entitlement is intended.")
    require("com.apple.developer.nfc.readersession.iso7816.select-identifiers" not in info, "No unverified SUBE AIDs may be declared.")
    require(privacy.get("NSPrivacyTracking") is False, "The app must not declare tracking.")
    require(privacy.get("NSPrivacyCollectedDataTypes") == [], "Local-only diagnostics must not declare remote collection.")
    require(any(entry.get("NSPrivacyAccessedAPIType") == "NSPrivacyAccessedAPICategoryUserDefaults" and "CA92.1" in entry.get("NSPrivacyAccessedAPITypeReasons", []) for entry in privacy.get("NSPrivacyAccessedAPITypes", [])), "App-only UserDefaults purpose is missing.")

    project = (ROOT / "Pulso.xcodeproj/project.pbxproj").read_text(encoding="utf-8")
    minimums = re.findall(r"IPHONEOS_DEPLOYMENT_TARGET\s*=\s*([\d.]+)", project)
    require(bool(minimums) and all(value == "26.0" for value in minimums), "Every declared deployment target must be iOS 26.0.")
    require('SWIFT_VERSION = 6.0;' in project, "Swift 6 language mode is required.")
    require('SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor' not in project, "Core NFC isolation is explicit; do not assume global MainActor.")
    require('TARGETED_DEVICE_FAMILY = 1;' in project, "Target must be iPhone.")
    require('MARKETING_VERSION = 0.2.0;' in project and 'CURRENT_PROJECT_VERSION = 2;' in project, "Release must be version 0.2.0, build 2.")
    require('path = Sources/Pulso;' in project and 'PBXFileSystemSynchronizedRootGroup' in project, "Source membership must include the synchronized source tree.")
    scheme = ET.parse(ROOT / "Pulso.xcodeproj/xcshareddata/xcschemes/Pulso.xcscheme")
    references = scheme.findall(".//BuildableReference")
    require(bool(references), "Shared scheme contains no build target.")
    for reference in references:
        require(reference.get("BlueprintIdentifier") in project, "Shared scheme points to a missing target.")
    require(any(reference.get("BlueprintName") == "PulsoUITests" for reference in scheme.findall(".//TestableReference/BuildableReference")), "Shared scheme must include native UI tests.")

    sources = list((ROOT / "Sources/Pulso").rglob("*.swift"))
    require(bool(sources), "Application Swift sources are missing.")
    require(any("@main" in file.read_text(encoding="utf-8") for file in sources), "SwiftUI app entry point is missing.")
    assets = ROOT / "Sources/Pulso/Resources/Assets.xcassets"
    icon_manifest = assets / "AppIcon.appiconset/Contents.json"
    require(icon_manifest.is_file(), "AppIcon asset manifest is missing.")
    icon_data = json.loads(icon_manifest.read_text(encoding="utf-8"))
    image_names = [entry["filename"] for entry in icon_data.get("images", []) if entry.get("filename")]
    require(bool(image_names), "AppIcon contains no image.")
    for image_name in image_names:
        path = icon_manifest.parent / image_name
        require(path.is_file(), f"Missing icon: {path.name}")
        with path.open("rb") as handle:
            header = handle.read(24)
        require(header[:8] == b"\x89PNG\r\n\x1a\n", f"Icon must be a real PNG: {path.name}")
        require(struct.unpack(">II", header[16:24]) == (1024, 1024), f"Unified app icon must be 1024x1024: {path.name}")
    for manifest in assets.rglob("Contents.json"):
        data = json.loads(manifest.read_text(encoding="utf-8"))
        for entry in data.get("images", []):
            if entry.get("filename"):
                require((manifest.parent / entry["filename"]).is_file(), f"Missing asset from {manifest}")

    for relative in [".github/workflows/ios.yml", "scripts/build_unsigned_ipa.sh", "scripts/verify_ipa.py", "scripts/run_ui_tests.py", "Tests/PulsoUITests/PulsoUITests.swift", "Package.swift"]:
        require((ROOT / relative).is_file(), f"Required build file missing: {relative}")
    print(f"PASS: project configuration, NFC entitlement, privacy manifest, shared scheme, {len(sources)} Swift source files, and icon resources.")
    print("Not executed here: Swift type checking, iOS build, app launch, or physical NFC detection.")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (ValueError, OSError, KeyError, ET.ParseError, plistlib.InvalidFileException) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        raise SystemExit(1)
