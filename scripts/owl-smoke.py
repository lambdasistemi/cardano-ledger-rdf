#!/usr/bin/env python3
"""OWL 2 RL inference smoke for vocabulary Turtle files.

For each fixture in `test/fixtures/vocab/smoke/*.n3`:
  1. Run EYE over the union of `vocab/**/*.ttl`, selected bundled OWL 2 RL
     rule fragments, and the fixture.
  2. Load the closure into rdflib.
  3. Execute each ASK query from the companion `<name>.ask` file. Each query
     is preceded by `# EXPECT: true|false`.

The gate fails on any EXPECT mismatch or inferred `owl:Nothing` instance.
"""
from __future__ import annotations

import shlex
import shutil
import subprocess
import sys
from pathlib import Path

import rdflib
from rdflib.namespace import OWL, RDF

REPO_ROOT = Path(__file__).resolve().parents[1]
SMOKE_DIR = REPO_ROOT / "test" / "fixtures" / "vocab" / "smoke"
VOCAB_ROOT = REPO_ROOT / "vocab"

OWL_RULE_FRAGMENTS = [
    "owl-sameAs.n3",
    "owl-inverseOf.n3",
    "owl-hasKey.n3",
    "owl-Nothing.n3",
]


def vocab_sources() -> list[Path]:
    return sorted(
        path
        for path in VOCAB_ROOT.glob("**/*.ttl")
        if not path.name.startswith("_")
    )


def find_eye_rule_dir() -> Path:
    eye_bin = shutil.which("eye")
    if eye_bin is None:
        raise SystemExit("error: `eye` not in PATH (are you inside `nix develop`?)")
    rule_dir = Path(eye_bin).resolve().parent.parent / "share" / "eye" / "rpo"
    if not rule_dir.is_dir():
        raise SystemExit(f"error: EYE rule directory not found at {rule_dir}")
    return rule_dir


def run_eye(closure_inputs: list[Path]) -> str:
    cmd = ["eye", "--nope", "--quiet", "--pass"] + [str(path) for path in closure_inputs]
    result = subprocess.run(cmd, capture_output=True, text=True, check=False)
    if result.returncode != 0:
        sys.stderr.write(result.stderr)
        raise SystemExit(f"error: eye exited {result.returncode}; cmd: {shlex.join(cmd)}")
    return result.stdout


def parse_ask_file(text: str) -> list[tuple[bool, str]]:
    lines = text.splitlines()
    preamble: list[str] = []
    blocks: list[tuple[bool, str]] = []
    current: list[str] | None = None
    current_expected: bool | None = None
    in_preamble = True

    for raw in lines:
        stripped = raw.strip()
        if stripped.startswith("# EXPECT:"):
            if current is not None and current_expected is not None:
                blocks.append((current_expected, "\n".join(preamble + current).strip()))
            verdict = stripped.split(":", 1)[1].strip().lower()
            if verdict not in {"true", "false"}:
                raise SystemExit(f"error: bad EXPECT verdict: {stripped!r}")
            current_expected = verdict == "true"
            current = []
            in_preamble = False
            continue
        if in_preamble:
            preamble.append(raw)
        else:
            assert current is not None
            current.append(raw)

    if current is not None and current_expected is not None:
        blocks.append((current_expected, "\n".join(preamble + current).strip()))
    return blocks


def main() -> int:
    sources = vocab_sources()
    if not sources:
        print("error: no Turtle files found under vocab/", file=sys.stderr)
        return 1

    if not SMOKE_DIR.exists():
        print(f"warning: no smoke directory at {SMOKE_DIR}; nothing to check", file=sys.stderr)
        return 0

    rule_dir = find_eye_rule_dir()
    rule_paths = [rule_dir / name for name in OWL_RULE_FRAGMENTS]
    for rule_path in rule_paths:
        if not rule_path.exists():
            raise SystemExit(f"error: missing rule fragment {rule_path}")

    fixtures = sorted(SMOKE_DIR.glob("*.n3"))
    if not fixtures:
        print(f"warning: no .n3 fixtures under {SMOKE_DIR}", file=sys.stderr)
        return 0

    failures: list[str] = []
    for fixture in fixtures:
        ask_file = fixture.with_suffix(".ask")
        if not ask_file.exists():
            failures.append(f"{fixture.name}: companion .ask file missing")
            continue

        closure_text = run_eye(sources + rule_paths + [fixture])
        closure_graph = rdflib.Graph()
        closure_graph.parse(data=closure_text, format="n3")

        for subject in closure_graph.subjects(RDF.type, OWL.Nothing):
            failures.append(f"{fixture.name}: inconsistency: {subject!r} a owl:Nothing")

        ask_blocks = parse_ask_file(ask_file.read_text())
        if not ask_blocks:
            failures.append(f"{fixture.name}: companion .ask file has no EXPECT blocks")
            continue

        for index, (expected, query) in enumerate(ask_blocks):
            verdict = bool(closure_graph.query(query).askAnswer)
            status = "ok" if verdict == expected else "fail"
            print(f"{status}: {fixture.name} ask#{index} expected={expected} got={verdict}")
            if verdict != expected:
                failures.append(
                    f"{fixture.name} ask#{index}: expected {expected}, got {verdict}"
                )

    if failures:
        print("", file=sys.stderr)
        for failure in failures:
            print(f"FAIL: {failure}", file=sys.stderr)
        return 1

    print(f"\nall {len(fixtures)} smoke fixture(s) passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
