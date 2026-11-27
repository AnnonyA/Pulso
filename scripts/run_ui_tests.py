#!/usr/bin/env python3
"""Run real XCTest UI scenarios on an iPhone 11 / iOS 26 simulator.

Creates a disposable simulator, never substitutes another device, and exports
native screenshots/xcresults even when a test fails. Requires macOS/Xcode.
"""
from __future__ import annotations
import json
import os
from pathlib import Path
import re
import shutil
import signal
import struct
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parents[1]
ARTIFACTS = ROOT / "build/ui-artifacts"
RESULTS = ROOT / "build/ui-results"
DEVICE_TYPE = "com.apple.CoreSimulator.SimDeviceType.iPhone-11"
SCENARIOS = [
    ("light", "light", "large", "test01ModesAndLaunchDefault", 5),
    ("dark", "dark", "large", "test02DarkAppearance", 1),
    ("large-text", "light", "accessibility-extra-extra-extra-large", "test03AccessibilityLargeText", 2),
]


def command(args: list[str], *, timeout: int = 60, log: Path | None = None, required: bool = True) -> str:
    print("$ " + " ".join(args), flush=True)
    if log is not None:
        log.parent.mkdir(parents=True, exist_ok=True)
    try:
        if log is None:
            completed = subprocess.run(args, cwd=ROOT, text=True, capture_output=True, timeout=timeout)
            output = completed.stdout
            error_output = completed.stderr
            code = completed.returncode
        else:
            with log.open("w", encoding="utf-8") as handle:
                process = subprocess.Popen(args, cwd=ROOT, stdout=handle, stderr=subprocess.STDOUT, start_new_session=True)
                try:
                    code = process.wait(timeout=timeout)
                except subprocess.TimeoutExpired:
                    os.killpg(process.pid, signal.SIGTERM)
                    try:
                        process.wait(timeout=10)
                    except subprocess.TimeoutExpired:
                        os.killpg(process.pid, signal.SIGKILL)
                        process.wait()
                    raise
            output = log.read_text(encoding="utf-8", errors="replace")
            error_output = output
    except subprocess.TimeoutExpired as error:
        message = f"Command timed out after {timeout}s: {args[0:4]}"
        if log and log.exists():
            print("\n".join(log.read_text(encoding="utf-8", errors="replace").splitlines()[-35:]), flush=True)
        if required:
            raise RuntimeError(message) from error
        print("WARNING: " + message, flush=True)
        return ""
    if code:
        print("\n".join(error_output.splitlines()[-45:]), flush=True)
        message = f"Command failed with exit {code}: {args[0:4]}"
        if log:
            message += f". Full log: {log.relative_to(ROOT)}"
        if required:
            raise RuntimeError(message)
        print("WARNING: " + message, flush=True)
    return output


def write_json(path: Path, data: object) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def versions(value: str) -> tuple[int, ...]:
    return tuple(int(part) for part in value.split("."))


def select_runtime() -> dict:
    inventory = json.loads(command(["xcrun", "simctl", "list", "--json"], timeout=90))
    write_json(ARTIFACTS / "simulator-inventory.json", inventory)
    available = [
        runtime for runtime in inventory.get("runtimes", [])
        if runtime.get("identifier", "").startswith("com.apple.CoreSimulator.SimRuntime.iOS-26-")
        and runtime.get("isAvailable", False)
    ]
    if not available:
        listed = [f"{runtime.get('name')}: available={runtime.get('isAvailable')}" for runtime in inventory.get("runtimes", [])]
        raise RuntimeError(
            "No available iOS 26 simulator runtime is installed. This test requires iPhone 11 with iOS 26; "
            "it will not silently substitute another OS/device. Installed runtimes: " + "; ".join(listed)
            + ". Install an iOS 26 runtime with Xcode Components or xcodebuild -downloadPlatform iOS -buildVersion 26.5, then rerun."
        )
    if not any(device.get("identifier") == DEVICE_TYPE for device in inventory.get("devicetypes", [])):
        raise RuntimeError(f"The selected Xcode does not expose the iPhone 11 device type ({DEVICE_TYPE}).")
    return max(available, key=lambda runtime: versions(runtime["version"]))


def attachment_names(value: object) -> dict[str, str]:
    names: dict[str, str] = {}
    if isinstance(value, dict):
        filename = value.get("exportedFileName")
        suggested = value.get("suggestedHumanReadableName")
        if isinstance(filename, str) and isinstance(suggested, str):
            names[filename] = suggested
        for child in value.values():
            names.update(attachment_names(child))
    elif isinstance(value, list):
        for child in value:
            names.update(attachment_names(child))
    return names


def export_result(scenario: str) -> list[dict]:
    bundle = RESULTS / f"{scenario}.xcresult"
    if not bundle.is_dir():
        return []
    destination = ARTIFACTS / "attachments" / scenario
    destination.mkdir(parents=True, exist_ok=True)
    command(
        ["xcrun", "xcresulttool", "export", "attachments", "--path", str(bundle), "--output-path", str(destination)],
        timeout=90, log=ARTIFACTS / "logs" / f"{scenario}-export.log", required=False,
    )
    summary = command(
        ["xcrun", "xcresulttool", "get", "test-results", "summary", "--path", str(bundle)],
        timeout=60, required=False,
    )
    if summary.strip():
        (ARTIFACTS / f"{scenario}-test-summary.json").write_text(summary, encoding="utf-8")
    names: dict[str, str] = {}
    for manifest in destination.rglob("manifest.json"):
        try:
            names.update(attachment_names(json.loads(manifest.read_text(encoding="utf-8"))))
        except (ValueError, OSError):
            pass
    screenshots = ARTIFACTS / "screenshots"
    screenshots.mkdir(exist_ok=True)
    entries = []
    for index, image in enumerate(sorted(destination.rglob("*.png")), 1):
        with image.open("rb") as handle:
            header = handle.read(24)
        if len(header) < 24 or header[:8] != b"\x89PNG\r\n\x1a\n":
            continue
        width, height = struct.unpack(">II", header[16:24])
        name = names.get(image.name, image.stem)
        safe = re.sub(r"[^A-Za-z0-9_.-]+", "-", name).strip("-.")[:140] or f"screenshot-{index}"
        filename = f"{scenario}-{index:02d}-{safe}.png"
        shutil.copyfile(image, screenshots / filename)
        entries.append({
            "scenario": scenario, "file": f"screenshots/{filename}",
            "width": width, "height": height, "attachmentName": name,
            "source": str(image.relative_to(ARTIFACTS)),
            "origin": "XCTest XCUIScreen screenshot from iPhone 11 simulator",
        })
    return entries


def main() -> int:
    if sys.platform != "darwin":
        print("ERROR: Real iOS UI tests require macOS/Xcode. Use the GitHub Actions workflow.", file=sys.stderr)
        return 1
    # Only disposable, project-local output directories are replaced.
    for directory in [ARTIFACTS, RESULTS]:
        if directory.exists():
            shutil.rmtree(directory)
        directory.mkdir(parents=True)
    (ARTIFACTS / "logs").mkdir()
    report: dict = {"status": "running", "device": "iPhone 11", "physicalNFCTest": False, "scenarios": []}
    device_id: str | None = None
    screenshots: list[dict] = []
    failure: str | None = None
    try:
        runtime = select_runtime()
        run_id = os.environ.get("GITHUB_RUN_ID", str(os.getpid()))
        device_id = command(["xcrun", "simctl", "create", f"Pulso-iPhone11-{run_id}", DEVICE_TYPE, runtime["identifier"]], timeout=90).strip()
        if not re.fullmatch(r"[0-9A-Fa-f-]{36}", device_id):
            raise RuntimeError("simctl did not return a valid device UDID.")
        report["simulator"] = {"udid": device_id, "deviceType": DEVICE_TYPE, "runtime": runtime}
        write_json(ARTIFACTS / "simulator-info.json", report["simulator"])
        print(f"Simulator: iPhone 11; runtime {runtime['version']} ({runtime.get('buildversion', 'build not supplied')}); UDID {device_id}", flush=True)
        boot_started = time.monotonic()
        command(["xcrun", "simctl", "boot", device_id], timeout=90)

        base = [
            "xcodebuild", "-project", "Pulso.xcodeproj", "-scheme", "Pulso", "-configuration", "Debug",
            "-sdk", "iphonesimulator", "-destination", f"platform=iOS Simulator,id={device_id}",
            "-destination-timeout", "90", "-derivedDataPath", "build/UISimulatorDerivedData",
            "-parallel-testing-enabled", "NO", "-maximum-concurrent-test-simulator-destinations", "1",
            "CODE_SIGNING_ALLOWED=NO", "CODE_SIGNING_REQUIRED=NO", "CODE_SIGN_IDENTITY=", "DEVELOPMENT_TEAM=",
            "IPHONEOS_DEPLOYMENT_TARGET=26.0",
        ]
        # A fresh iOS 26 simulator performs data migration on first boot. Build
        # while it initializes, so compiler errors remain independently visible.
        # The first observed CI boot needed more than 240s in CoreLocationMigrator.
        command(base + ["build-for-testing"], timeout=720, log=ARTIFACTS / "logs/build-for-testing.log")
        print("Simulator build completed; waiting for full native boot readiness (maximum 600s).", flush=True)
        command(["xcrun", "simctl", "bootstatus", device_id, "-b"], timeout=600, log=ARTIFACTS / "logs/boot.log")
        report["simulator"]["bootCompletedAfterSeconds"] = round(time.monotonic() - boot_started, 2)
        report["simulator"]["bootStatusWaitLimitSeconds"] = 600
        write_json(ARTIFACTS / "simulator-info.json", report["simulator"])
        command(["xcrun", "simctl", "status_bar", device_id, "override", "--time", "9:41", "--dataNetwork", "wifi", "--wifiMode", "active", "--wifiBars", "3", "--batteryState", "charged", "--batteryLevel", "100"], required=False)
        for scenario, appearance, text_size, method, minimum_screenshots in SCENARIOS:
            command(["xcrun", "simctl", "ui", device_id, "appearance", appearance])
            command(["xcrun", "simctl", "ui", device_id, "content_size", text_size])
            result = {"name": scenario, "appearance": appearance, "contentSize": text_size, "test": method, "status": "running"}
            report["scenarios"].append(result)
            try:
                command(base + [
                    "-only-testing:PulsoUITests/PulsoUITests/" + method,
                    "-resultBundlePath", str(RESULTS / f"{scenario}.xcresult"),
                    "-test-timeouts-enabled", "YES", "-default-test-execution-time-allowance", "120",
                    "-maximum-test-execution-time-allowance", "180", "test-without-building",
                ], timeout=420, log=ARTIFACTS / "logs" / f"{scenario}-tests.log")
                result["status"] = "passed"
            except RuntimeError:
                result["status"] = "failed"
                raise
            finally:
                captures = export_result(scenario)
                screenshots.extend(captures)
                result["screenshotCount"] = len(captures)
            valid = [image for image in captures if (image["width"], image["height"]) == (828, 1792)]
            if len(valid) < minimum_screenshots:
                raise RuntimeError(
                    f"{scenario}: expected at least {minimum_screenshots} real 828x1792 iPhone 11 screenshots; found {len(valid)}. "
                    "Inspect the xcresult and screenshot export logs."
                )
        report["status"] = "passed"
    except (RuntimeError, OSError, ValueError) as error:
        failure = str(error)
        report["status"] = "failed"
        report["error"] = failure
        print("ERROR: " + failure, file=sys.stderr, flush=True)
    finally:
        write_json(ARTIFACTS / "screenshots-index.json", screenshots)
        write_json(ARTIFACTS / "ui-test-summary.json", report)
        if device_id:
            command(["xcrun", "simctl", "spawn", device_id, "log", "show", "--last", "10m", "--style", "compact", "--predicate", 'process == "Pulso" OR process CONTAINS "PulsoUITests"'], timeout=60, log=ARTIFACTS / "logs/simulator-app.log", required=False)
            if failure:
                command(["xcrun", "simctl", "io", device_id, "screenshot", str(ARTIFACTS / "failure-final-screen.png")], timeout=30, required=False)
            command(["xcrun", "simctl", "shutdown", device_id], timeout=60, required=False)
            command(["xcrun", "simctl", "delete", device_id], timeout=60, required=False)
    if failure:
        return 1
    print(f"PASS: {len(SCENARIOS)} real simulator scenarios; {len(screenshots)} native screenshot attachments. Physical NFC still requires an iPhone and card.", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
