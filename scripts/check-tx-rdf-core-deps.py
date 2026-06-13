#!/usr/bin/env python3
"""Verify that tx-rdf-core excludes fat package-boundary dependencies."""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path


TARGET = "tx-rdf-core:lib:tx-rdf-core"
PLAN = Path("dist-newstyle/cache/plan.json")
SOURCE_ROOT = Path("tx-rdf-core/src")
CLOSURE_FORBIDDEN = {
    "http-client",
    "http-client-tls",
    "libyaml",
    "optparse-applicative",
    "yaml",
}
DIRECT_FORBIDDEN = {
    "directory",
    "filepath",
    "process",
}
SOURCE_FORBIDDEN = (
    "System.Directory",
    "System.FilePath",
    "System.IO",
    "System.Process",
)


def load_plan() -> tuple[dict[str, object], list[str]]:
    try:
        plan = json.loads(PLAN.read_text(encoding="utf-8"))
    except FileNotFoundError:
        print(f"{PLAN} does not exist after cabal dry-run", file=sys.stderr)
        raise SystemExit(1)

    units = {unit["id"]: unit for unit in plan.get("install-plan", [])}
    roots = [
        unit["id"]
        for unit in units.values()
        if unit.get("pkg-name") == "tx-rdf-core"
        and unit.get("component-name", "lib") in {"lib", "lib:tx-rdf-core"}
    ]
    if not roots:
        print("tx-rdf-core library was not present in the Cabal plan", file=sys.stderr)
        raise SystemExit(1)
    return units, roots


def closure_ids(units: dict[str, object], roots: list[str]) -> set[str]:
    seen: set[str] = set()
    stack = list(roots)
    while stack:
        unit_id = stack.pop()
        if unit_id in seen:
            continue
        seen.add(unit_id)
        unit = units[unit_id]
        for dep in unit.get("depends", []):
            if dep not in seen:
                stack.append(dep)
    return seen


def package_names(units: dict[str, object], unit_ids: set[str]) -> set[str]:
    return {units[unit_id]["pkg-name"] for unit_id in unit_ids if unit_id in units}


def direct_dependency_names(units: dict[str, object], roots: list[str]) -> set[str]:
    deps = set()
    for root in roots:
        for dep in units[root].get("depends", []):
            deps.add(units[dep]["pkg-name"])
    return deps


def check_source_imports() -> list[str]:
    matches: list[str] = []
    for path in sorted(SOURCE_ROOT.rglob("*.hs")):
        text = path.read_text(encoding="utf-8")
        for needle in SOURCE_FORBIDDEN:
            if needle in text:
                matches.append(f"{path}: contains {needle}")
    return matches


def path_to_package(
    units: dict[str, object],
    roots: list[str],
    package: str,
) -> list[str]:
    stack = [(root, [root]) for root in roots]
    seen = set(roots)
    while stack:
        unit_id, path = stack.pop(0)
        if units[unit_id].get("pkg-name") == package:
            return path
        for dep in units[unit_id].get("depends", []):
            if dep not in seen:
                seen.add(dep)
                stack.append((dep, path + [dep]))
    return []


def render_path(units: dict[str, object], unit_ids: list[str]) -> str:
    return " -> ".join(units[unit_id]["pkg-name"] for unit_id in unit_ids)


def print_transitive_note(
    units: dict[str, object],
    roots: list[str],
    closure: set[str],
) -> None:
    found = sorted(DIRECT_FORBIDDEN & package_names(units, closure))
    if not found:
        return
    print("transitive filesystem/process packages are present only through required dependencies:")
    for package in found:
        path = path_to_package(units, roots, package)
        print(f"- {package}: {render_path(units, path)}")


def main() -> int:
    configure = subprocess.run(
        ["cabal", "build", TARGET, "-O0", "--dry-run"],
        check=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
    )
    if configure.returncode != 0:
        sys.stdout.write(configure.stdout)
        return configure.returncode

    units, roots = load_plan()
    closure = closure_ids(units, roots)
    closure_packages = package_names(units, closure)

    found = sorted(CLOSURE_FORBIDDEN & closure_packages)
    if found:
        print("tx-rdf-core dependency closure contains forbidden fat packages:")
        for package in found:
            print(f"- {package}")
        return 1

    direct_found = sorted(DIRECT_FORBIDDEN & direct_dependency_names(units, roots))
    if direct_found:
        print("tx-rdf-core has forbidden direct filesystem/process dependencies:")
        for package in direct_found:
            print(f"- {package}")
        return 1

    source_found = check_source_imports()
    if source_found:
        print("tx-rdf-core source contains forbidden filesystem/process module references:")
        for match in source_found:
            print(f"- {match}")
        return 1

    print("tx-rdf-core closure excludes HTTP/YAML/optparse fat packages")
    print("tx-rdf-core has no direct directory/filepath/process dependencies")
    print("tx-rdf-core source has no System.Directory/FilePath/IO/Process references")
    print_transitive_note(units, roots, closure)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
