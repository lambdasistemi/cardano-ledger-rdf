#!/usr/bin/env bash
# gate.sh — present until PR is ready for review.
# Validates the commit shape for every new commit on this branch.
set -euo pipefail

# Helper: commit_gate (Conventional Commits + Tasks: T019-S<n> trailer)
commit_gate() {
  local range="$1"
  local fail=0
  for sha in $(git log --format=%H "$range" 2>/dev/null); do
    local subject body
    subject=$(git log -1 --format=%s "$sha")
    body=$(git log -1 --format=%B "$sha")
    # Conventional Commit subject
    if ! echo "$subject" | grep -qE '^(feat|fix|chore|docs|test|refactor|perf|style|ci|build)(\(.+\))?: .+'; then
      echo "✗ $sha subject not conventional-commit: $subject" >&2
      fail=1
    fi
    # Tasks: trailer (except merges, except the very first planning commit)
    if [ "$(git log -1 --format=%P "$sha" | wc -w)" -eq 1 ]; then
      if ! echo "$body" | grep -qE '^Tasks: T019-(S[1-3]|C|F)(, T019-(S[1-3]|C|F))*$'; then
        # Tolerate the planning commit
        if echo "$subject" | grep -qE '^(chore|docs)\(specs?\): '; then
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

# Default: validate every new commit on this branch vs origin/main
RANGE="${1:-origin/main..HEAD}"
commit_gate "$RANGE"
