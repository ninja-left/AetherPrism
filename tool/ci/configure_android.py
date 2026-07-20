#!/usr/bin/env python3
"""Configure the generated Android project for Aether Prism CI builds."""

from __future__ import annotations

import argparse
import base64
import os
import re
from pathlib import Path

CI_START = "// AETHER_PRISM_CI_START"
CI_END = "// AETHER_PRISM_CI_END"


def _replace_managed_block(text: str, block: str) -> str:
    pattern = re.compile(rf"{re.escape(CI_START)}.*?{re.escape(CI_END)}\n?", re.DOTALL)
    if pattern.search(text):
        return pattern.sub(block, text, count=1)
    return text


def _insert_after_first(text: str, marker: str, insert: str) -> str:
    idx = text.find(marker)
    if idx == -1:
        return insert + text
    idx += len(marker)
    return text[:idx] + insert + text[idx:]


def _patch_groovy_build_gradle(path: Path, namespace: str, application_id: str) -> None:
    text = path.read_text(encoding="utf-8")

    if "import java.io.FileInputStream" not in text:
        text = "import java.io.FileInputStream\n" + text
    if "import java.util.Properties" not in text:
        text = "import java.util.Properties\n" + text

    managed = f"""{CI_START}

def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {{
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}}

    signingConfigs {{
        release {{
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }}
    }}
{CI_END}
"""
    text = _replace_managed_block(text, managed)
    if managed not in text:
        text = _insert_after_first(text, "android {\n", managed)

    text = re.sub(
        r'(?m)^\s*namespace\s+["\'][^"\']+["\']\s*$',
        f'    namespace "{namespace}"',
        text,
        count=1,
    )
    text = re.sub(
        r'(?m)^\s*applicationId\s+["\'][^"\']+["\']\s*$',
        f'        applicationId "{application_id}"',
        text,
        count=1,
    )

    build_idx = text.find("buildTypes {")
    if build_idx != -1:
        release_idx = text.find("release {\n", build_idx)
        if release_idx != -1:
            insertion = "            signingConfig signingConfigs.release\n"
            pos = release_idx + len("release {\n")
            text = text[:pos] + insertion + text[pos:]

    path.write_text(text, encoding="utf-8")


def _patch_kts_build_gradle(path: Path, namespace: str, application_id: str) -> None:
    text = path.read_text(encoding="utf-8")

    if "import java.io.FileInputStream" not in text:
        text = "import java.io.FileInputStream\n" + text
    if "import java.util.Properties" not in text:
        text = "import java.util.Properties\n" + text

    managed = f"""{CI_START}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {{
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}}

    signingConfigs {{
        create("release") {{
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            val storeFilePath = keystoreProperties["storeFile"] as String
            storeFile = file(storeFilePath)
            storePassword = keystoreProperties["storePassword"] as String
        }}
    }}
{CI_END}
"""
    text = _replace_managed_block(text, managed)
    if managed not in text:
        text = _insert_after_first(text, "android {\n", managed)

    text = re.sub(
        r'(?m)^\s*namespace\s*=\s*["\'][^"\']+["\']\s*$',
        f'    namespace = "{namespace}"',
        text,
        count=1,
    )
    text = re.sub(
        r'(?m)^\s*applicationId\s*=\s*["\'][^"\']+["\']\s*$',
        f'        applicationId = "{application_id}"',
        text,
        count=1,
    )

    build_idx = text.find("buildTypes {")
    if build_idx != -1:
        release_idx = text.find("release {\n", build_idx)
        if release_idx != -1:
            insertion = '            signingConfig = signingConfigs.getByName("release")\n'
            pos = release_idx + len("release {\n")
            text = text[:pos] + insertion + text[pos:]

    path.write_text(text, encoding="utf-8")


def _patch_manifest(path: Path, application_id: str) -> None:
    text = path.read_text(encoding="utf-8")
    text = re.sub(r'package="[^"]+"', f'package="{application_id}"', text, count=1)
    text = re.sub(r'package\s*=\s*"[^"]+"', f'package="{application_id}"', text, count=1)
    path.write_text(text, encoding="utf-8")


def _patch_main_activity(android_root: Path, namespace: str) -> None:
    src_root = android_root / "app" / "src" / "main"
    candidates = list(src_root.rglob("MainActivity.kt")) + list(src_root.rglob("MainActivity.java"))
    if not candidates:
        return

    source = candidates[0]
    text = source.read_text(encoding="utf-8")
    text = re.sub(r'^package\s+[^\n]+$', f'package {namespace}', text, count=1, flags=re.MULTILINE)

    ext = source.suffix
    target = src_root / ("kotlin" if ext == ".kt" else "java") / Path(*namespace.split(".")) / source.name
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(text, encoding="utf-8")
    if source.resolve() != target.resolve():
        try:
            source.unlink()
        except FileNotFoundError:
            pass

    current = source.parent
    while current != src_root and current.exists():
        try:
            current.rmdir()
        except OSError:
            break
        current = current.parent


def _write_keystore(android_root: Path, keystore_base64: str) -> None:
    app_dir = android_root / "app"
    app_dir.mkdir(parents=True, exist_ok=True)
    (app_dir / "upload-keystore.jks").write_bytes(base64.b64decode(keystore_base64))


def _write_key_properties(android_root: Path, store_password: str, key_alias: str, key_password: str) -> None:
    key_properties = android_root / "key.properties"
    key_properties.write_text(
        "\n".join(
            [
                f"storePassword={store_password}",
                f"keyPassword={key_password}",
                f"keyAlias={key_alias}",
                "storeFile=../app/upload-keystore.jks",
                "",
            ]
        ),
        encoding="utf-8",
    )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--android-root", default="android")
    parser.add_argument("--application-id", default="io.github.aetherprism")
    parser.add_argument("--namespace", default=None)
    parser.add_argument("--keystore-base64", default=os.environ.get("ANDROID_KEYSTORE_BASE64", ""))
    parser.add_argument("--keystore-password", default=os.environ.get("ANDROID_KEYSTORE_PASSWORD", ""))
    parser.add_argument("--key-alias", default=os.environ.get("ANDROID_KEY_ALIAS", ""))
    parser.add_argument("--key-password", default=os.environ.get("ANDROID_KEY_PASSWORD", ""))
    args = parser.parse_args()

    android_root = Path(args.android_root)
    namespace = args.namespace or args.application_id

    groovy = android_root / "app" / "build.gradle"
    kts = android_root / "app" / "build.gradle.kts"

    if groovy.exists():
        _patch_groovy_build_gradle(groovy, namespace, args.application_id)
    elif kts.exists():
        _patch_kts_build_gradle(kts, namespace, args.application_id)
    else:
        raise FileNotFoundError("Could not find android/app/build.gradle or android/app/build.gradle.kts")

    manifest = android_root / "app" / "src" / "main" / "AndroidManifest.xml"
    if manifest.exists():
        _patch_manifest(manifest, args.application_id)

    _patch_main_activity(android_root, namespace)

    if args.keystore_base64:
        _write_keystore(android_root, args.keystore_base64)
        _write_key_properties(android_root, args.keystore_password, args.key_alias, args.key_password)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
