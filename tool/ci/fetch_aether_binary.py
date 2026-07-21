#!/usr/bin/env python3
"""Download and stage the latest upstream Aether binary for CI builds."""

from __future__ import annotations

import argparse
import json
import os
import shutil
import sys
import tarfile
import tempfile
import urllib.request
import zipfile
from pathlib import Path

REPO = "CluvexStudio/Aether"
API = "https://api.github.com/repos/{repo}/releases/latest"

ASSET_MAP = {
    ("linux", "x86_64"): "aether-linux-x86_64.tar.gz",
    ("linux", "arm64"): "aether-linux-arm64.tar.gz",
    ("macos", "x86_64"): "aether-macos-x86_64.tar.gz",
    ("macos", "arm64"): "aether-macos-arm64.tar.gz",
    ("windows", "x86_64"): "aether-windows-x86_64.zip",
    ("android", "arm64"): "aether-android-arm64.tar.gz",
    ("android", "armv7"): "aether-android-armv7.tar.gz",
    ("android", "x86_64"): "aether-android-x86_64.tar.gz",
}


def _download_json(url: str) -> dict:
    request = urllib.request.Request(url, headers={"User-Agent": "AetherPrism CI"})
    with urllib.request.urlopen(request) as response:
        return json.loads(response.read().decode("utf-8"))


def _download_file(url: str, destination: Path) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    request = urllib.request.Request(url, headers={"User-Agent": "AetherPrism CI"})
    with urllib.request.urlopen(request) as response, destination.open("wb") as out:
        shutil.copyfileobj(response, out)


def _find_release_asset(release: dict, asset_name: str) -> dict:
    for asset in release.get("assets", []):
        if asset.get("name") == asset_name:
            return asset
    raise SystemExit(f"Could not find {asset_name} in the latest Aether release")


def _find_executable(root: Path) -> Path:
    candidates = [
        *root.rglob("aether"),
        *root.rglob("aether.exe"),
    ]
    for candidate in candidates:
        if candidate.is_file():
            return candidate
    files = [path for path in root.rglob("*") if path.is_file()]
    if len(files) == 1:
        return files[0]
    raise SystemExit(f"Could not locate the extracted Aether binary inside {root}")


def _extract_archive(archive_path: Path, output_path: Path) -> None:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as tmpdir:
        tmp = Path(tmpdir)
        if archive_path.suffix == ".zip":
            with zipfile.ZipFile(archive_path) as zf:
                zf.extractall(tmp)
        else:
            with tarfile.open(archive_path, mode="r:*") as tf:
                tf.extractall(tmp)

        binary = _find_executable(tmp)
        shutil.copy2(binary, output_path)

    if os.name != "nt":
        output_path.chmod(0o755)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--platform", required=True, choices=["linux", "macos", "windows", "android"])
    parser.add_argument("--arch", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--repo", default=REPO)
    parser.add_argument("--tag", default="latest")
    args = parser.parse_args()

    asset_name = ASSET_MAP.get((args.platform, args.arch))
    if asset_name is None:
        raise SystemExit(f"Unsupported platform/arch combination: {args.platform}/{args.arch}")

    if args.tag == "latest":
        release_url = API.format(repo=args.repo)
    else:
        release_url = f"https://api.github.com/repos/{args.repo}/releases/tags/{args.tag}"

    release = _download_json(release_url)
    asset = _find_release_asset(release, asset_name)

    with tempfile.TemporaryDirectory() as tmpdir:
        archive_path = Path(tmpdir) / asset_name
        _download_file(asset["browser_download_url"], archive_path)
        _extract_archive(archive_path, Path(args.output))

    print(f"Staged {asset_name} -> {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
