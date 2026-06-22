#!/usr/bin/env python3
"""Assemble deployable function sources.

Cloud Functions buildpacks deploy a single source directory, so the shared
library must be vendored *into* each function. This script stages each service
plus a copy of backend/services/shared/ under terraform/.build/src/<service>/, which is
what the Terraform cloud_function module zips and uploads.

Run before `terraform plan/apply`:

    python build.py
"""

from __future__ import annotations

import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SERVICES = ROOT / "backend" / "services"
SHARED = SERVICES / "shared"
BUILD = ROOT / "terraform" / ".build" / "src"

FUNCTIONS = ["orders_api", "notify_restaurant", "notify_user"]


def stage(name: str) -> None:
    src = SERVICES / name
    dst = BUILD / name
    if dst.exists():
        shutil.rmtree(dst)
    dst.mkdir(parents=True)

    # Copy the service's own files (main.py, requirements.txt).
    for item in src.iterdir():
        if item.name == "__pycache__":
            continue
        shutil.copy2(item, dst / item.name)

    # Vendor the shared package as a subpackage importable as `shared`.
    shutil.copytree(
        SHARED,
        dst / "shared",
        ignore=shutil.ignore_patterns("__pycache__", "*.pyc"),
    )
    print(f"  staged {name} -> {dst.relative_to(ROOT)}")


def main() -> None:
    print("Assembling function sources...")
    for fn in FUNCTIONS:
        stage(fn)
    print("Done.")


if __name__ == "__main__":
    main()
