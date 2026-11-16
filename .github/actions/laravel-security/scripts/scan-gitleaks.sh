#!/usr/bin/env bash
set -Eeuo pipefail

command -v gitleaks >/dev/null || { echo 'gitleaks not installed' >&2; exit 2; }
GITLEAKS_CONFIG="${GITLEAKS_CONFIG:-.gitleaks.toml}"
test -f "$GITLEAKS_CONFIG" || { echo "Missing $GITLEAKS_CONFIG" >&2; exit 2; }

# Current tree catches secrets in unchanged code as well as new PR code.
# NOTE: Current-tree findings can include existing technical debt.
set +e
gitleaks dir --config "$GITLEAKS_CONFIG" --redact --exit-code 1 .
TREE_RESULT=$?
set -e

# PR commit range also catches a secret added and then removed in a later commit.
# This does NOT scan all of the repository's historical commits.
HISTORY_RESULT=0
if [[ -n "${PR_BASE_REF:-}" ]]; then
  if ! git rev-parse --verify "refs/remotes/origin/${PR_BASE_REF}^{commit}" >/dev/null 2>&1; then
    echo "Cannot resolve origin/${PR_BASE_REF}; fetch-depth: 0 required" >&2
    HISTORY_RESULT=2
  else
    BASE_SHA="$(git merge-base "refs/remotes/origin/${PR_BASE_REF}" HEAD)" || {
      echo 'Cannot compute PR merge base' >&2
      exit 2
    }
    echo "Scanning PR Git commits from merge base ${BASE_SHA:0:12} to HEAD"
    set +e
    gitleaks git --config "$GITLEAKS_CONFIG" --redact --exit-code 1 "--log-opts=${BASE_SHA}..HEAD" .
    HISTORY_RESULT=$?
    set -e
  fi
fi

if [[ "$TREE_RESULT" -ne 0 || "$HISTORY_RESULT" -ne 0 ]]; then
  echo "Gitleaks gate FAILED: tree=$TREE_RESULT, PR-history=$HISTORY_RESULT" >&2
  exit 1
fi
echo 'Gitleaks gate PASSED.'
