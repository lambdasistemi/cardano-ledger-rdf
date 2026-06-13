#!/usr/bin/env bash
set -euo pipefail
commit_gate() {
  local range="$1"
  local fail=0
  for sha in $(git log --format=%H "$range" 2>/dev/null); do
    local subject body
    subject=$(git log -1 --format=%s "$sha")
    body=$(git log -1 --format=%B "$sha")
    if ! printf '%s\n' "$subject" \
      | grep -qE '^(feat|fix|chore|docs|test|refactor|perf|style|ci|build|revert)(\([^)]+\))?!?: .+'; then
      echo "x $sha subject not conventional-commit: $subject" >&2
      fail=1
    fi
    if [ "$(git log -1 --format=%P "$sha" | wc -w)" -eq 1 ]; then
      case "$subject" in
        chore*|docs*|build*|ci*|style*|revert*) ;;
        *)
          if ! printf '%s\n' "$body" \
            | grep -qE '^Tasks:[[:space:]]*T[0-9]+([[:space:]]*,[[:space:]]*T[0-9]+)*[[:space:]]*$'; then
            echo "x $sha missing or malformed Tasks: trailer" >&2
            fail=1
          fi
          ;;
      esac
    fi
  done
  return $fail
}

git diff --check
RANGE="${1:-origin/main..HEAD}"
commit_gate "$RANGE"
