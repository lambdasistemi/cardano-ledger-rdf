#!/usr/bin/env python3
"""Validate every public Turtle vocabulary file under vocab/.

This is the local equivalent of the graph-browser validate-action used by
cardano-knowledge-maps, simplified for this repository: the vocabulary source
of truth is `vocab/**/*.ttl`, with private `_*.ttl` files ignored.
"""
from __future__ import annotations

import sys
from pathlib import Path

import rdflib

REPO_ROOT = Path(__file__).resolve().parents[1]
VOCAB_ROOT = REPO_ROOT / "vocab"


def vocab_sources() -> list[Path]:
    return sorted(
        path
        for path in VOCAB_ROOT.glob("**/*.ttl")
        if not path.name.startswith("_")
    )


def main() -> int:
    sources = vocab_sources()
    if not sources:
        print("error: no Turtle files found under vocab/", file=sys.stderr)
        return 1

    failed = 0
    total_triples = 0
    for ttl_path in sources:
        rel_path = ttl_path.relative_to(REPO_ROOT)
        graph = rdflib.Graph()
        try:
            graph.parse(source=str(ttl_path), format="turtle")
        except Exception as exc:
            print(f"error: {rel_path}: {exc}", file=sys.stderr)
            failed += 1
            continue
        triples = len(graph)
        total_triples += triples
        print(f"ok: {rel_path}: {triples} triples")

    if failed:
        print(f"\n{failed} vocab file(s) failed to parse", file=sys.stderr)
        return 1

    print(f"\nall {len(sources)} vocab Turtle file(s) parsed; {total_triples} triples total")
    return 0


if __name__ == "__main__":
    sys.exit(main())
