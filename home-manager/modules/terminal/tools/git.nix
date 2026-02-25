# Git version control with enforced GPG signing, global hooks, and quality-of-life settings.

{
  pkgs,
  pkgsStable,
  constants,
  ...
}:

{
  home.packages = [
    pkgsStable.git-interactive-rebase-tool # Better interactive rebase UI
  ];

  programs = {
    difftastic = {
      enable = true;
      git.enable = true;
    };

    git = {
      enable = true;

      # === Signing (defense layer 1/3: auto-sign every commit and tag) ===
      signing = {
        key = constants.user.signingKey;
        format = "openpgp";
        signByDefault = true; # sets commit.gpgSign + tag.gpgSign = true
      };

      # === Global hooks (applied to ALL repos via core.hooksPath) ===
      # Each hook chains to repo-local .git/hooks/<name> if it exists,
      # so per-project hooks (e.g. just install-hooks) still work.
      hooks = {
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
          _local_hook="$(git rev-parse --git-dir 2>/dev/null)/hooks/pre-commit"
          if [[ -x "$_local_hook" ]]; then
            exec "$_local_hook" "$@"
          fi
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
          _local_hook="$(git rev-parse --git-dir 2>/dev/null)/hooks/commit-msg"
          if [[ -x "$_local_hook" ]]; then
            exec "$_local_hook" "$@"
          fi
        '';

        # Defense layer 2/3: warn immediately if commit is unsigned.
        # Catches --no-gpg-sign bypass. post-commit always runs (even with --no-verify).
        post-commit = pkgs.writeShellScript "git-hook-post-commit" ''
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
          _local_hook="$(git rev-parse --git-dir 2>/dev/null)/hooks/pre-push"
          if [[ -x "$_local_hook" ]]; then
            echo "$input" | "$_local_hook" "$@"
            exit $?
          fi
        '';
      };

      settings = {
        user = {
          inherit (constants.user) name email;
        };

        # === Pull / Push ===
        pull.rebase = true; # clean history by default
        push = {
          autoSetupRemote = true; # no more --set-upstream
          gpgSign = "if-asked"; # sign pushes when server supports it
        };

        # === Merge / Rebase ===
        merge.conflictstyle = "zdiff3"; # better conflict markers with common ancestor
        rerere.enabled = true; # remember conflict resolutions
        rebase = {
          autoStash = true; # auto stash/pop dirty tree on rebase
          autoSquash = true; # auto-apply fixup!/squash! commits
          updateRefs = true; # update stacked branches on rebase
        };

        # === Diff ===
        diff.algorithm = "histogram"; # better diff quality

        # === Fetch ===
        fetch = {
          prune = true; # clean dead remote branches
          pruneTags = true; # clean dead remote tags
          fsckobjects = true; # integrity check on fetch
        };

        # === Transfer integrity ===
        transfer.fsckobjects = true;
        receive.fsckobjects = true;

        # === Interactive rebase ===
        sequence.editor = "interactive-rebase-tool";

        # === UI ===
        column.ui = "auto";
        branch.sort = "-committerdate"; # recent branches first
        tag.sort = "-version:refname"; # newest version tags first
        log.date = "iso";
        status.showUntrackedFiles = "all"; # show individual untracked files

        # === Defaults ===
        init.defaultBranch = "main";
        help.autocorrect = "prompt"; # ask before running corrected command

        alias = {
          st = "status";
          co = "checkout";
          br = "branch";
          lg = "log --oneline --graph --decorate";
          lga = "log --oneline --graph --decorate --all";
          ad = "add";
          cm = "commit -m";
          amend = "commit --amend --no-edit";
          pl = "pull";
          ps = "push";
          df = "diff";
          dft = "diff --cached";
          rs = "restore";
          rst = "restore --staged";
          rb = "rebase";
          rbi = "rebase -i";
          rset = "reset";
          tg = "tag";
          tga = "tag -a";
          cl = "clean -fdi";
          sm = "submodule";
          smu = "submodule update --init --recursive";
          rmt = "remote";
          rmtv = "remote -v";
          cp = "cherry-pick";
          stsh = "stash";
          stshl = "stash list";
          stsha = "stash apply";
          stshd = "stash drop";
          cfg = "config --list";
          cfgg = "config --global --list";
          ign = "!git check-ignore -v";
          recent = "branch --sort=-committerdate --format='%(committerdate:relative)\t%(refname:short)'";
          undo = "reset --soft HEAD~1";
          wip = "!git add -A && git commit -m 'wip: work in progress [skip ci]'";
          aliases = "!git config --get-regexp alias | sort";
          changelog = "!git-cliff -o CHANGELOG.md"; # generate changelog (requires git-cliff)
        };
      };

      includes = [
        {
          condition = "hasconfig:remote.*.url:https://github.com/**";
          contents.user.email = constants.user.githubEmail;
        }
        {
          condition = "hasconfig:remote.*.url:git@github.com:*/**";
          contents.user.email = constants.user.githubEmail;
        }
      ];

      ignores = [
        ".cache/"
        ".DS_Store"
        ".idea/"
        "*.swp"
        "*.elc"
        "auto-save-list"
        ".direnv/"
        "node_modules"
        "result"
        "result-*"
        ".beads/"
      ];
    };
  };
}
