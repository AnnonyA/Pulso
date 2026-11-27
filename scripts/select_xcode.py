#!/usr/bin/env python3
"""Choose an installed, stable Xcode with an iPhone SDK >=26. No downloads."""
from __future__ import annotations
import os
from pathlib import Path
import plistlib
import re
import subprocess
import sys


def main() -> int:
    candidates: list[tuple[tuple[int, ...], Path]] = []
    for app in Path("/Applications").glob("Xcode*.app"):
        if "beta" in app.name.lower():
            continue
        try:
            with (app / "Contents/Info.plist").open("rb") as handle:
                info = plistlib.load(handle)
            version = tuple(int(x) for x in str(info["CFBundleShortVersionString"]).split("."))
            if version[0] < 26:
                continue
            developer = app / "Contents/Developer"
            env = dict(os.environ, DEVELOPER_DIR=str(developer))
            result = subprocess.run(
                ["/usr/bin/xcrun", "--sdk", "iphoneos", "--show-sdk-version"],
                text=True, capture_output=True, env=env, check=True,
            )
            if int(re.match(r"\d+", result.stdout.strip()).group()) >= 26:
                candidates.append((version, developer))
        except (OSError, KeyError, ValueError, AttributeError, subprocess.CalledProcessError):
            continue
    if not candidates:
        print("ERROR: no stable Xcode 26+ with an iPhoneOS 26+ SDK is installed.", file=sys.stderr)
        return 1
    # Keep the iOS 26 toolchain while one is available; otherwise accept a newer one.
    compatible = [entry for entry in candidates if entry[0][0] == 26] or candidates
    version, selected = max(compatible, key=lambda entry: entry[0])
    line = f"DEVELOPER_DIR={selected}\n"
    if path := os.environ.get("GITHUB_ENV"):
        with open(path, "a", encoding="utf-8") as handle:
            handle.write(line)
        print(f"Selected Xcode {'.'.join(map(str, version))}: {selected}")
    else:
        print(line, end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
