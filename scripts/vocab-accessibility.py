#!/usr/bin/env python3
"""Vocabulary accessibility check.

For every public Turtle vocabulary file under `vocab/`:

1.  Parse the file with rdflib.
2.  Look up the expected namespace IRI in the static
    ``EXPECTED_NAMESPACES`` table (keyed by the path under ``vocab/``).
3.  Assert every declared class (subject of ``rdf:type rdfs:Class``) and
    every declared property (subject of ``rdf:type rdf:Property``) has an
    IRI under that namespace, and that every such IRI is unique within
    the file.
4.  Assert the file is mirrored verbatim into ``docs/vocab/`` so MkDocs
    publishes it at the URL the namespace IRI was claiming to dereference
    to.

Run this from the repository root via ``python3 scripts/vocab-accessibility.py``
(the ``vocab-accessibility`` Nix check does this automatically in CI).
"""

from __future__ import annotations

import sys
from pathlib import Path

import rdflib
from rdflib.namespace import RDF, RDFS, OWL

REPO_ROOT = Path(__file__).resolve().parents[1]
VOCAB_ROOT = REPO_ROOT / "vocab"
DOCS_VOCAB_ROOT = REPO_ROOT / "docs" / "vocab"

SITE_BASE = "https://lambdasistemi.github.io/cardano-ledger-rdf"

# Static manifest. Keyed by path under vocab/, value is the prefix IRI
# the file is responsible for.
EXPECTED_NAMESPACES: dict[str, str] = {
    "cardano/transactions.ttl": f"{SITE_BASE}/vocab/cardano#",
    "treasury/overlay.ttl": f"{SITE_BASE}/vocab/treasury#",
}


def vocab_sources() -> list[Path]:
    return sorted(
        path
        for path in VOCAB_ROOT.glob("**/*.ttl")
        if not path.name.startswith("_")
    )


def check_file(ttl_path: Path) -> list[str]:
    rel = ttl_path.relative_to(VOCAB_ROOT).as_posix()
    failures: list[str] = []

    expected_ns = EXPECTED_NAMESPACES.get(rel)
    if expected_ns is None:
        failures.append(
            f"{rel}: no entry in EXPECTED_NAMESPACES; add one to "
            f"scripts/vocab-accessibility.py or rename the file"
        )
        return failures

    graph = rdflib.Graph()
    try:
        graph.parse(source=str(ttl_path), format="turtle")
    except Exception as exc:  # pragma: no cover - parse-time message
        failures.append(f"{rel}: parse failed: {exc}")
        return failures

    # Subjects declared as a Class or a Property must live under the
    # expected namespace IRI, and must be unique.
    declared_iris: set[rdflib.URIRef] = set()
    for subject in graph.subjects(RDF.type, RDFS.Class):
        if not isinstance(subject, rdflib.URIRef):
            continue
        if not str(subject).startswith(expected_ns):
            failures.append(
                f"{rel}: class IRI not in expected namespace {expected_ns}: {subject}"
            )
        if subject in declared_iris:
            failures.append(f"{rel}: class IRI declared twice: {subject}")
        declared_iris.add(subject)

    for subject in graph.subjects(RDF.type, RDF.Property):
        if not isinstance(subject, rdflib.URIRef):
            continue
        if not str(subject).startswith(expected_ns):
            failures.append(
                f"{rel}: property IRI not in expected namespace {expected_ns}: {subject}"
            )
        if subject in declared_iris:
            failures.append(f"{rel}: predicate IRI declared twice: {subject}")
        declared_iris.add(subject)

    if not declared_iris:
        failures.append(
            f"{rel}: no rdf:Property or rdfs:Class declarations found under {expected_ns}"
        )

    # The file must also be reachable from docs/vocab so MkDocs serves
    # it at the dereference URL the namespace IRI claims to point at.
    docs_mirror = DOCS_VOCAB_ROOT / rel
    if not docs_mirror.exists():
        failures.append(
            f"{rel}: not mirrored at docs/vocab/{rel}; "
            f"add a symlink or copy so the namespace IRI dereferences"
        )
    elif docs_mirror.is_symlink():
        # rdflib should still parse the file via the symlink; assert
        # the bytes match the source so the published file is verbatim.
        if docs_mirror.read_bytes() != ttl_path.read_bytes():
            failures.append(
                f"{rel}: docs/vocab/{rel} symlink content does not match source"
            )
    else:
        if docs_mirror.read_bytes() != ttl_path.read_bytes():
            failures.append(
                f"{rel}: docs/vocab/{rel} content drifted from vocab/{rel}; "
                f"replace the docs-side copy with a symlink"
            )

    # Optional sanity: the ontology header should declare itself with
    # owl:Ontology. Both shipped vocabs do this today; flag if not.
    ontology_subjects = list(graph.subjects(RDF.type, OWL.Ontology))
    if not ontology_subjects:
        failures.append(f"{rel}: no owl:Ontology declaration found")

    if not failures:
        print(
            f"ok: {rel}: namespace={expected_ns} declarations={len(declared_iris)} "
            f"docs-mirrored=yes"
        )

    return failures


def self_test() -> int:
    """Adversarial sanity test: synthesize a tampered TTL and confirm the
    check actually fails on it. This ensures the gate is not a no-op.

    Invoked via ``python3 scripts/vocab-accessibility.py --self-test``.
    """

    import tempfile
    import textwrap

    bad = textwrap.dedent(
        """
        @prefix cardano: <http://wrong.example/cardano#> .
        @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
        @prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
        @prefix owl: <http://www.w3.org/2002/07/owl#> .

        <http://wrong.example/cardano> a owl:Ontology .
        cardano:Transaction a rdfs:Class .
        cardano:hasInput a rdf:Property .
        """
    ).strip()

    with tempfile.TemporaryDirectory() as tmpdir:
        tmp = Path(tmpdir) / "cardano" / "transactions.ttl"
        tmp.parent.mkdir(parents=True)
        tmp.write_text(bad, encoding="utf-8")
        # Run the check, pointing at the temp tree by monkey-patching
        # module-level constants and seeing failures arise.
        global VOCAB_ROOT, DOCS_VOCAB_ROOT
        original_vocab = VOCAB_ROOT
        original_docs = DOCS_VOCAB_ROOT
        try:
            VOCAB_ROOT = Path(tmpdir)
            DOCS_VOCAB_ROOT = Path(tmpdir) / "docs"  # missing => fail
            failures = check_file(tmp)
        finally:
            VOCAB_ROOT = original_vocab
            DOCS_VOCAB_ROOT = original_docs

    expected_phrases = [
        "class IRI not in expected namespace",
        "property IRI not in expected namespace",
        "not mirrored at docs/vocab",
    ]
    missing = [
        phrase
        for phrase in expected_phrases
        if not any(phrase in f for f in failures)
    ]
    if missing:
        print(
            "self-test FAILED: tampered TTL did not produce expected failures",
            file=sys.stderr,
        )
        for phrase in missing:
            print(f"  missing expected failure: {phrase!r}", file=sys.stderr)
        for failure in failures:
            print(f"  observed: {failure}", file=sys.stderr)
        return 1

    print(f"self-test ok: tampered TTL produced {len(failures)} expected failures")
    return 0


def main(argv: list[str]) -> int:
    if "--self-test" in argv:
        return self_test()

    sources = vocab_sources()
    if not sources:
        print("error: no Turtle files found under vocab/", file=sys.stderr)
        return 1

    all_failures: list[str] = []
    for ttl_path in sources:
        failures = check_file(ttl_path)
        for failure in failures:
            print(f"FAIL: {failure}", file=sys.stderr)
        all_failures.extend(failures)

    if all_failures:
        print(
            f"\n{len(all_failures)} accessibility check(s) failed across "
            f"{len(sources)} vocab file(s)",
            file=sys.stderr,
        )
        return 1

    print(f"\nall {len(sources)} vocab file(s) accessible at their declared IRIs")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
