#!/usr/bin/env bash
set -euo pipefail
commit_gate() {
  local range="$1"
  local fail=0
  for sha in $(git log --format=%H "$range" 2>/dev/null); do
    local subject body
    subject=$(git log -1 --format=%s "$sha")
    body=$(git log -1 --format=%B "$sha")
    if ! echo "$subject" | grep -qE '^(feat|fix|chore|docs|test|refactor|perf|style|ci|build)(\(.+\))?: .+'; then
      echo "✗ $sha subject not conventional-commit: $subject" >&2
      fail=1
    fi
    if [ "$(git log -1 --format=%P "$sha" | wc -w)" -eq 1 ]; then
      if ! echo "$body" | grep -qE '^Tasks: T004-(S[1-9]|F)(, T004-(S[1-9]|F))*$'; then
        if echo "$subject" | grep -qE '^(chore|docs)\(spec[s]?\): '; then
          :
        else
          echo "✗ $sha missing or malformed Tasks: trailer" >&2
          fail=1
        fi
      fi
    fi
  done
  return $fail
}
RANGE="${1:-origin/main..HEAD}"
commit_gate "$RANGE"
