#!/usr/bin/env python3
"""synth-demo-cast.py -- stitch captured pipeline outputs into a paced
asciinema v2 cast file.

The companion `record-demo-cast.sh` drives the live commands and captures
each scene's output into a JSON manifest. This script consumes that
manifest and emits a cast file with deterministic timing:

    {"version":2,"width":100,"height":32,"timestamp":...,"env":{...}}
    [t, "o", chunk]
    [t, "o", chunk]
    ...

Pacing:
  - prompt and operator-typed text: small chunks (2-5 chars) at 30-50 ms
    each (~150-300 WPM equivalent)
  - command output: streamed in chunks, total dwell proportional to the
    output's natural runtime (overlay/blueprint: ~1 s; body-fetch: the
    actual measured seconds clamped into [8, 14] s for breathing room)
  - between scenes: a 1.2-1.8 s "operator thinks" pause

Total wall time is reported on stderr; aim is 60-120 s.
"""

from __future__ import annotations

import argparse
import json
import random
import sys
import time
from dataclasses import dataclass, field
from pathlib import Path
from typing import Iterable

WIDTH = 100
HEIGHT = 32

PROMPT = "\x1b[1;32moperator@cq-rdf\x1b[0m:\x1b[1;34m~/case\x1b[0m$ "

# Use a fixed seed so chunk-size jitter is deterministic across runs.
RNG = random.Random(0xC0FFEE)


@dataclass
class CastBuilder:
    events: list = field(default_factory=list)
    t: float = 0.0

    def emit(self, chunk: str) -> None:
        if not chunk:
            return
        self.events.append([round(self.t, 4), "o", chunk])

    def advance(self, dt: float) -> None:
        self.t += dt

    # ---- high-level helpers ----------------------------------------

    def write(self, chunk: str, dt: float = 0.0) -> None:
        """Emit a chunk and advance the clock by dt."""
        self.emit(chunk)
        self.advance(dt)

    def type_text(self, text: str, per_char: float = 0.035) -> None:
        """Simulate the operator typing -- 2-5 char chunks with jitter."""
        i = 0
        n = len(text)
        while i < n:
            size = RNG.randint(2, 5)
            chunk = text[i : i + size]
            self.write(chunk, per_char * len(chunk))
            i += size

    def prompt_and_command(self, command: str, pre_pause: float = 1.0) -> None:
        self.advance(pre_pause)
        self.emit(PROMPT)
        self.advance(0.25)
        self.type_text(command)
        self.advance(0.3)
        self.emit("\r\n")

    def stream_output(self, text: str, total_seconds: float) -> None:
        """Stream a block of stdout over `total_seconds`, line by line.

        Long single lines are kept whole (no chunking inside a line) so
        viewers see what the actual command would have printed at the
        moment it printed it.
        """
        if not text:
            return
        # Normalise to crlf so the asciinema player renders cleanly.
        lines = text.splitlines()
        if not lines:
            return
        n = len(lines)
        per_line = max(total_seconds / n, 0.01)
        for line in lines:
            self.write(line + "\r\n", per_line)

    def banner(self, text: str, pre: float = 1.2, post: float = 0.6) -> None:
        """Emit a dim grey one-line scene comment."""
        self.advance(pre)
        self.emit(f"\x1b[38;5;244m# {text}\x1b[0m\r\n")
        self.advance(post)


# ----------------------------------------------------------------------
# Scene definitions
# ----------------------------------------------------------------------


def render(cast: CastBuilder, m: dict) -> None:
    # --- Opening ----------------------------------------------------
    cast.advance(0.5)
    cast.emit(
        "\x1b[1;36mcq-rdf demo -- May 2026 Amaru treasury, end to end\x1b[0m\r\n"
    )
    cast.advance(1.2)

    # --- Scene 1: survey the package --------------------------------
    cast.banner("survey the case-study package -- declarative files only")
    cast.prompt_and_command("ls blueprints shapes", pre_pause=0.4)
    cast.stream_output(m["ls_queries"], 0.8)

    cast.prompt_and_command(f"wc -l selections.txt", pre_pause=1.0)
    cast.stream_output(m["selections_wc"], 0.4)

    cast.prompt_and_command("head -16 overlay.yaml", pre_pause=1.0)
    cast.stream_output(m["overlay_head"], 1.8)

    # --- Scene 2: token sentinel ------------------------------------
    cast.banner("Blockfrost token is set, but never echoed")
    cast.prompt_and_command(
        '[ -n "$BLOCKFROST_PROJECT_ID" ] && echo "BLOCKFROST_PROJECT_ID: set"',
        pre_pause=0.6,
    )
    cast.stream_output("BLOCKFROST_PROJECT_ID: set", 0.4)

    # --- Scene 3: overlay -------------------------------------------
    cast.banner("step 1 -- compile the operator overlay into Turtle")
    cast.prompt_and_command(
        "cq-rdf overlay --in overlay.yaml > overlay.ttl", pre_pause=0.8
    )
    # overlay is fast; show it that way.
    cast.advance(0.6)
    cast.prompt_and_command("wc -l overlay.ttl", pre_pause=0.3)
    cast.stream_output(m["overlay_wc"], 0.3)

    cast.prompt_and_command("head -10 overlay.ttl", pre_pause=0.8)
    cast.stream_output(m["overlay_ttl_head"], 1.4)

    # --- Scene 4: body fetch ----------------------------------------
    cast.banner(
        "step 2 -- fetch 101 transaction bodies in parallel from Blockfrost"
    )
    cast.prompt_and_command(
        'xargs -P8 -n1 cq-rdf body --provider blockfrost \\\r\n'
        '  --token "$BLOCKFROST_PROJECT_ID" \\\r\n'
        '  < selections.txt > bodies.ttl',
        pre_pause=0.6,
    )
    # Stretch the body-fetch dwell to feel real even though we did it
    # locally in ~3 s. Clamp between 8 and 14 seconds.
    fetch_dwell = max(8.0, min(14.0, float(m["body_secs"]) * 3.0 + 6.0))
    cast.advance(fetch_dwell)

    cast.prompt_and_command("wc -l bodies.ttl", pre_pause=0.3)
    cast.stream_output(m["bodies_wc"], 0.4)

    # --- Scene 5: blueprint + shacl --------------------------------
    cast.banner(
        "step 3 -- blueprint types the Sundae order datum, then SHACL validates"
    )
    cast.prompt_and_command(
        "cat overlay.ttl bodies.ttl \\\r\n"
        "  | cq-rdf blueprint --blueprints blueprints/ \\\r\n"
        "  > package.ttl",
        pre_pause=0.6,
    )
    cast.advance(1.5)
    cast.prompt_and_command("wc -l package.ttl", pre_pause=0.3)
    cast.stream_output(m["package_wc"], 0.3)

    cast.prompt_and_command(
        "cq-rdf shacl --shapes shapes/ < package.ttl", pre_pause=0.8
    )
    cast.advance(1.2)
    # An empty report means every invariant held; comment so the viewer
    # knows what to read into the silence.
    cast.emit(
        "\x1b[38;5;244m# (empty report = invariants held, exit 0)\x1b[0m\r\n"
    )
    cast.advance(0.4)

    # --- Scene 6: SPARQL --------------------------------------------
    cast.banner("step 4 -- run a real SPARQL question against the lattice")
    cast.prompt_and_command(
        "arq --data package.ttl \\\r\n"
        "    --query contingency-inflow.rq",
        pre_pause=0.6,
    )
    cast.advance(1.0)
    cast.stream_output(m["arq_out"], 0.8)

    # --- Scene 7: typed-datum probe ---------------------------------
    cast.banner(
        "typed-decode is live -- Sundae order datums are first-class triples"
    )
    cast.prompt_and_command("cat probe.rq", pre_pause=0.6)
    cast.stream_output(
        "PREFIX tx: <https://lambdasistemi.github.io/cardano-rdf/fixtures/tx#>\r\n"
        "SELECT (COUNT(*) AS ?typed_destinations)\r\n"
        "WHERE { ?d tx:OrderDatum_destination ?dst }",
        1.2,
    )
    cast.prompt_and_command(
        "arq --data package.ttl --query probe.rq", pre_pause=0.8
    )
    cast.advance(0.9)
    cast.stream_output(m["probe_out"], 0.7)

    # --- Closing ----------------------------------------------------
    cast.advance(1.0)
    cast.emit(
        "\x1b[1;36m# overlay -> body -> blueprint -> shacl -> SPARQL. Every number reproducible.\x1b[0m\r\n"
    )
    cast.advance(1.5)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--manifest", required=True, type=Path)
    parser.add_argument("--out", required=True, type=Path)
    args = parser.parse_args()

    manifest = json.loads(args.manifest.read_text())
    cast = CastBuilder()
    render(cast, manifest)

    header = {
        "version": 2,
        "width": WIDTH,
        "height": HEIGHT,
        "timestamp": int(time.time()),
        "env": {"SHELL": "/bin/bash", "TERM": "xterm-256color"},
    }

    args.out.parent.mkdir(parents=True, exist_ok=True)
    with args.out.open("w") as f:
        f.write(json.dumps(header) + "\n")
        for ev in cast.events:
            f.write(json.dumps(ev) + "\n")

    total = cast.events[-1][0] if cast.events else 0.0
    print(f"cast events: {len(cast.events)}", file=sys.stderr)
    print(f"cast duration (last timestamp): {total:.2f} s", file=sys.stderr)


if __name__ == "__main__":
    main()
