#!/usr/bin/env python3
"""Validate a built IPA's actual arm64 iPhone Mach-O, deployment floor and resources."""
from __future__ import annotations
import argparse
import json
from pathlib import Path, PurePosixPath
import plistlib
import struct
import sys
import zipfile


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def version_tuple(encoded: int) -> tuple[int, int, int]:
    return (encoded >> 16, (encoded >> 8) & 0xff, encoded & 0xff)


def inspect_ipa(path: Path) -> dict:
    with zipfile.ZipFile(path) as archive:
        names = archive.namelist()
        for name in names:
            pure = PurePosixPath(name)
            require(not pure.is_absolute() and ".." not in pure.parts, "Unsafe path in IPA.")
        prefix = "Payload/Pulso.app/"
        require(prefix + "Info.plist" in names, "Payload/Pulso.app/Info.plist is absent.")
        info = plistlib.loads(archive.read(prefix + "Info.plist"))
        minimum = tuple(map(int, info.get("MinimumOSVersion", "0").split(".")))
        minimum = minimum + (0,) * (3 - len(minimum))
        require(minimum == (26, 0, 0), "MinimumOSVersion must be 26.0, including the first iOS 26 release.")
        require(info.get("CFBundleSupportedPlatforms") == ["iPhoneOS"], "This must be a device build, never a simulator archive.")
        require(info.get("UIDeviceFamily") == [1], "The built app must target iPhone.")
        executable = info.get("CFBundleExecutable", "")
        require(bool(executable) and "/" not in executable, "Executable name is invalid.")
        binary = archive.read(prefix + executable)
        require(len(binary) >= 32, "Executable is missing or truncated.")
        magic, cpu, subtype, filetype, count, command_bytes, flags, reserved = struct.unpack_from("<IiiIIIII", binary)
        require(magic == 0xfeedfacf, "Executable is not a thin, little-endian 64-bit Mach-O.")
        require(cpu == 0x0100000c, "Executable is not arm64 for a real iPhone.")
        require(filetype == 2, "Mach-O is not an executable.")
        require(32 + command_bytes <= len(binary), "Mach-O load command table is truncated.")
        cursor = 32
        deployment = None
        for _ in range(count):
            require(cursor + 8 <= 32 + command_bytes, "Truncated Mach-O command.")
            command, size = struct.unpack_from("<II", binary, cursor)
            require(size >= 8 and cursor + size <= 32 + command_bytes, "Invalid Mach-O command size.")
            if command == 0x32:  # LC_BUILD_VERSION
                require(size >= 24, "Invalid LC_BUILD_VERSION.")
                platform, minos, sdk, tools = struct.unpack_from("<IIII", binary, cursor + 8)
                require(platform == 2, "Mach-O platform is not iOS; simulator binaries are rejected.")
                require(version_tuple(minos) == (26, 0, 0), "Mach-O deployment target must be iOS 26.0.")
                deployment = {"platform": "iOS", "minimumOS": "26.0", "sdk": ".".join(map(str, version_tuple(sdk)))}
            cursor += size
        require(deployment is not None, "No iOS build-version command in executable.")
        require(prefix + "Assets.car" in names, "Compiled asset catalog is missing.")
        require(prefix + "PrivacyInfo.xcprivacy" in names, "Bundled privacy manifest is missing.")
        require(bool(info.get("NFCReaderUsageDescription")), "Built NFC usage description is missing.")
        require(not any(name.endswith(".swift") for name in names), "Source files must not be disguised as a compiled IPA.")
        return {
            "ipa": path.name,
            "bundleIdentifier": info.get("CFBundleIdentifier"),
            "version": info.get("CFBundleShortVersionString"),
            "build": info.get("CFBundleVersion"),
            "architecture": "arm64",
            "deployment": deployment,
            "executableBytes": len(binary),
            "provisioningProfilePresent": prefix + "embedded.mobileprovision" in names,
            "signing": "unsigned; external signing and valid NFC provisioning required",
        }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("ipa", type=Path)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    result = inspect_ipa(args.ipa)
    rendered = json.dumps(result, indent=2, ensure_ascii=False) + "\n"
    if args.output:
        args.output.write_text(rendered, encoding="utf-8")
    print(rendered, end="")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError, KeyError, zipfile.BadZipFile, struct.error) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        raise SystemExit(1)
