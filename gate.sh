#!/usr/bin/env bash
set -euo pipefail
commit_gate() {
  local range="$1"; local fail=0
  for sha in $(git log --format=%H "$range" 2>/dev/null); do
    local subject body
    subject=$(git log -1 --format=%s "$sha")
    body=$(git log -1 --format=%B "$sha")
    if ! echo "$subject" | grep -qE '^(feat|fix|chore|docs|test|refactor|perf|style|ci|build)(\(.+\))?: .+'; then
      echo "✗ $sha subject not conventional-commit: $subject" >&2; fail=1
    fi
    if [ "$(git log -1 --format=%P "$sha" | wc -w)" -eq 1 ]; then
      if ! echo "$body" | grep -qE '^Tasks: (drep-rerun|T005-S1|T006-S1|T007-S1|T013-S1|T014-S1|T017-S1|T022-(S[1-2]|F)|T026-(S1|F)|T028-S1|T030-S1|T031-S1|T040-S1|T056-S1|T059-S1|T061-S1|T062-(F|S1|S2|S3|P)|T066-(P2|P3|P4|P5|P6|DOCS|CAST)|T076-(S1|S2|S3|S3a|S3b|S3c|S4|S5)|T078-CAST|T086-(S[1-4]|F))(, (drep-rerun|T005-S1|T006-S1|T007-S1|T013-S1|T014-S1|T017-S1|T022-(S[1-2]|F)|T026-(S1|F)|T028-S1|T030-S1|T031-S1|T040-S1|T056-S1|T059-S1|T061-S1|T062-(F|S1|S2|S3|P)|T066-(P2|P3|P4|P5|P6|DOCS|CAST)|T076-(S1|S2|S3|S3a|S3b|S3c|S4|S5)|T078-CAST|T086-(S[1-4]|F)))*$'; then
        if echo "$subject" | grep -qE '^(chore|docs)\(spec[s]?\): '; then
          :
        else
          echo "✗ $sha missing or malformed Tasks: trailer" >&2; fail=1
        fi
      fi
    fi
  done
  return $fail
}
RANGE="${1:-origin/main..HEAD}"
commit_gate "$RANGE"
