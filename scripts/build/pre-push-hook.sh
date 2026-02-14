#!/usr/bin/env bash
# pre-push-hook.sh - Block pushes containing unsigned commits.
# Install: just install-hooks

set -euo pipefail

zero_sha="0000000000000000000000000000000000000000"
failed=0

echo "Pre-push: verifying commit signatures..."

while read -r local_ref local_sha remote_ref remote_sha; do
  # Branch/tag deletion push: nothing to verify.
  if [[ "$local_sha" == "$zero_sha" ]]; then
    continue
  fi

  if [[ "$remote_sha" == "$zero_sha" ]]; then
    range="$local_sha"
  else
    range="${remote_sha}..${local_sha}"
  fi

  mapfile -t commits < <(git rev-list "$range")

  for commit in "${commits[@]}"; do
    if ! git verify-commit "$commit" >/dev/null 2>&1; then
      echo "✗ Unsigned or invalid commit: ${commit} (${local_ref} -> ${remote_ref})"
      failed=1
    fi
  done
done

if [[ "$failed" -ne 0 ]]; then
  echo "Push rejected. All commits must have valid signatures."
  echo "Fix by amending with signature: git commit --amend -S --no-edit"
  exit 1
fi

echo "✔ All pushed commits have valid signatures."
