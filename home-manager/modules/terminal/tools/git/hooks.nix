# Global git hooks: secret scanning, conventional commits, GPG signing enforcement.

{ pkgs, ... }:

let
  mkLocalHookExec = hookName: ''
    _local_hook="$(git rev-parse --git-dir 2>/dev/null)/hooks/${hookName}"
    if [[ -x "$_local_hook" ]]; then
      exec "$_local_hook" "$@"
    fi
  '';

  mkLocalHookPipe = hookName: ''
    _local_hook="$(git rev-parse --git-dir 2>/dev/null)/hooks/${hookName}"
    if [[ -x "$_local_hook" ]]; then
      echo "$input" | "$_local_hook" "$@"
      exit $?
    fi
  '';
in

{
  programs.git.hooks = {
    pre-commit = pkgs.writeShellScript "git-hook-pre-commit" ''
      set -euo pipefail

      # --- Secret scanning (gitleaks) ---
      if ! ${pkgs.gitleaks}/bin/gitleaks protect --staged --no-banner --redact 2>&1; then
        echo ""
        echo "✗ Pre-commit: secrets detected in staged changes. Remove them before committing."
        exit 1
      fi

      # --- Large file detection (>5MB) ---
      max_size=$((5 * 1024 * 1024))
      while IFS= read -r file; do
        if [[ -f "$file" ]]; then
          size=$(stat --format=%s "$file" 2>/dev/null || echo 0)
          if [[ "$size" -gt "$max_size" ]]; then
            echo "✗ Pre-commit: file exceeds 5MB: $file ($((size / 1024 / 1024))MB)"
            echo "  Use git-lfs for large files."
            exit 1
          fi
        fi
      done < <(git diff --cached --name-only --diff-filter=ACM)

      # --- Merge conflict markers ---
      conflict_files=$(git diff --cached --name-only --diff-filter=ACM \
        | xargs -r grep -lE '<{7}|>{7}|={7}' 2>/dev/null || true)
      if [[ -n "$conflict_files" ]]; then
        echo "✗ Pre-commit: merge conflict markers found in:"
        echo "$conflict_files" | sed 's/^/  /'
        exit 1
      fi

      # --- Trailing whitespace (warning only) ---
      if ! git diff --cached --check >/dev/null 2>&1; then
        echo "⚠ Pre-commit: trailing whitespace detected. Consider fixing."
      fi

      # --- Chain to repo-local hook ---
      ${mkLocalHookExec "pre-commit"}
    '';

    commit-msg = pkgs.writeShellScript "git-hook-commit-msg" ''
      set -euo pipefail

      msg_file="$1"
      msg=$(head -1 "$msg_file")

      # Skip automated commit messages
      if [[ "$msg" =~ ^(Merge|Revert|fixup!|squash!|amend!|Initial\ commit) ]]; then
        exit 0
      fi

      # Conventional commit format: type(scope)?: description
      pattern='^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert|wip)(\(.+\))?!?: .+'
      if ! [[ "$msg" =~ $pattern ]]; then
        echo "✗ Commit message does not follow conventional commit format."
        echo ""
        echo "  Format: <type>[optional scope]: <description>"
        echo "  Types:  feat fix docs style refactor perf test build ci chore revert wip"
        echo "  Example: feat(auth): add JWT validation"
        echo ""
        echo "  Got: $msg"
        exit 1
      fi

      # --- Chain to repo-local hook ---
      ${mkLocalHookExec "commit-msg"}
    '';

    # Defense layer 2/3: warn immediately if commit is unsigned.
    # Catches --no-gpg-sign bypass. post-commit always runs (even with --no-verify).
    post-commit = pkgs.writeShellScript "git-hook-post-commit" ''
      if [[ "$(git config --bool --get mysystem.gitanon || echo false)" == "true" ]]; then
        exit 0
      fi

      if ! git verify-commit HEAD >/dev/null 2>&1; then
        echo ""
        echo "⚠ WARNING: Latest commit is NOT GPG-signed!"
        echo "  Fix: git commit --amend -S --no-edit"
        echo ""
      fi
    '';

    # Defense layer 3/3: final gate — block unsigned commits from leaving the machine.
    pre-push = pkgs.writeShellScript "git-hook-pre-push" ''
      set -euo pipefail

      zero_sha="0000000000000000000000000000000000000000"
      failed=0

      # Save stdin for chaining to repo-local hook
      input=$(cat)

      if [[ "$(git config --bool --get mysystem.gitanon || echo false)" == "true" ]]; then
        echo "⚠ Anonymous mode enabled: skipping GPG signature enforcement."
        ${mkLocalHookPipe "pre-push"}
        exit 0
      fi

      while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        read -r local_ref local_sha remote_ref remote_sha <<< "$line"

        # Skip branch/tag deletion
        if [[ "$local_sha" == "$zero_sha" ]]; then
          continue
        fi

        if [[ "$remote_sha" == "$zero_sha" ]]; then
          range="$local_sha"
        else
          range="''${remote_sha}..''${local_sha}"
        fi

        mapfile -t commits < <(git rev-list "$range" 2>/dev/null)

        for commit in "''${commits[@]}"; do
          if ! git verify-commit "$commit" >/dev/null 2>&1; then
            echo "✗ Unsigned commit: ''${commit:0:12} (''${local_ref} -> ''${remote_ref})"
            failed=1
          fi
        done
      done <<< "$input"

      if [[ "$failed" -ne 0 ]]; then
        echo ""
        echo "Push rejected. All commits must have valid GPG signatures."
        echo "Fix: git rebase --exec 'git commit --amend -S --no-edit' <base>"
        exit 1
      fi

      echo "✔ All commits have valid GPG signatures."

      # --- Chain to repo-local hook ---
      ${mkLocalHookPipe "pre-push"}
    '';
  };
}
