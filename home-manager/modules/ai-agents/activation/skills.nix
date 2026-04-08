# Skill installation activation script.
# Bootstraps skills CLI, installs configured skills with retry, manages state caching.

{
  cfg,
  lib,
  pkgs,
  toJSON,
}:

let
  normalizedSkills = lib.unique cfg.skills;
  normalizedOmitSkills = lib.unique cfg.omitSkills;
  desiredSkillStateJson = toJSON {
    skills = normalizedSkills;
    omitSkills = normalizedOmitSkills;
    agents = {
      claude = cfg.claude.enable;
      opencode = cfg.opencode.enable;
    };
  };
  repoLevelRepos = builtins.filter builtins.isString normalizedSkills;
  # Pre-generate install commands at Nix eval time
  skillCommands = map (
    s:
    if builtins.isString s then
      # Repo-level: skills add "owner/repo" --global --all --yes
      ''
        processed_entries=$((processed_entries + 1))
        echo "  [$processed_entries/$configured_entries] ${s}"
        echo "  → ${s}"
        echo "  [AI] starting install for ${s} at $(date +'%F %T')"
        total_attempts=$((total_attempts + 1))
        if ! attempt_cmd "install ${s}" "$SKILLS_BIN" add "${s}" --global --all --yes "''${skill_agent_scope_args[@]}"; then
          echo "❌ Failed to install ${s}"
          failed_installs=$((failed_installs + 1))
        else
          echo "✔ Installed ${s}"
          successful_installs=$((successful_installs + 1))
        fi
      ''
    else if lib.elem s.repo repoLevelRepos then
      # Skip redundant per-skill install when repo-level --all is already present.
      ''
        processed_entries=$((processed_entries + 1))
        echo "  [$processed_entries/$configured_entries] ${s.repo}#${s.skill}"
        echo "  → ${s.repo}#${s.skill}"
        echo "  ⏭ Skipped ${s.repo}#${s.skill} (repo ${s.repo} already installed with --all)"
        skipped_installs=$((skipped_installs + 1))
      ''
    else
      # Individual: skills add https://github.com/owner/repo --skill name --global --yes
      ''
        processed_entries=$((processed_entries + 1))
        echo "  [$processed_entries/$configured_entries] ${s.repo}#${s.skill}"
        echo "  → ${s.repo}#${s.skill}"
        echo "  [AI] starting install for ${s.repo}#${s.skill} at $(date +'%F %T')"
        total_attempts=$((total_attempts + 1))
        if ! attempt_cmd "install ${s.repo}#${s.skill}" "$SKILLS_BIN" add "https://github.com/${s.repo}" --skill "${s.skill}" --global --yes "''${skill_agent_scope_args[@]}"; then
          echo "❌ Failed to install ${s.repo}#${s.skill}"
          failed_installs=$((failed_installs + 1))
        else
          echo "✔ Installed ${s.repo}#${s.skill}"
          successful_installs=$((successful_installs + 1))
        fi
      ''
  ) normalizedSkills;
  omitCommands = map (skill: ''
    omit_processed=$((omit_processed + 1))
    echo "  [omit $omit_processed/$omit_total] ${skill}"
        if ! attempt_cmd "remove omitted skill ${skill}" "$SKILLS_BIN" remove "${skill}" --global --yes "''${skill_agent_scope_args[@]}"; then
      echo "❌ Failed to remove omitted skill ${skill}"
      omit_failures=$((omit_failures + 1))
      failed_installs=$((failed_installs + 1))
    else
      echo "✔ Removed omitted skill ${skill}"
    fi
  '') normalizedOmitSkills;
in
lib.mkIf (cfg.skills != [ ]) (
  lib.hm.dag.entryAfter [ "writeBoundary" "createJSWorkspace" ] ''
    export BUN_INSTALL="$HOME/.bun"
    export PATH="${pkgs.git}/bin:${pkgs.nodejs}/bin:${pkgs.bun}/bin:$BUN_INSTALL/bin:$PATH"

    SKILLS_BIN="$BUN_INSTALL/bin/skills"
    if [[ ! -x "$SKILLS_BIN" ]]; then
      SKILLS_BIN="$(command -v skills 2>/dev/null || true)"
    fi

    if [[ -z "$SKILLS_BIN" ]]; then
      echo "📦 skills CLI missing, bootstrapping with bun..."
      if ! $DRY_RUN_CMD "${pkgs.bun}/bin/bun" add --global --cwd "$HOME" --no-summary skills; then
        echo "❌ Failed to bootstrap skills CLI"
        exit 1
      fi

      SKILLS_BIN="$BUN_INSTALL/bin/skills"
      if [[ ! -x "$SKILLS_BIN" ]]; then
        SKILLS_BIN="$(command -v skills 2>/dev/null || true)"
      fi
    fi

    if [[ -z "$SKILLS_BIN" ]]; then
      echo "❌ skills CLI not found after bootstrap"
      exit 1
    fi

    if ! command -v git >/dev/null 2>&1; then
      echo "❌ git is required for skills installation but is not in PATH"
      exit 1
    fi

    declare -a skill_agents=()
    if [[ -d "$HOME/.claude" ]]; then
      skill_agents+=(claude-code)
    fi

    # Do not install skills.sh packs into the shared ~/.agents/skills tree for
    # OpenCode. OpenCode already has explicit per-profile local skills under
    # ~/.config/opencode*/skills, and the shared tree causes massive duplicate
    # skill discovery warnings and large log files.

    declare -a skill_agent_scope_args=()
    if [[ "''${#skill_agents[@]}" -gt 0 ]]; then
      for skill_agent in "''${skill_agents[@]}"; do
        skill_agent_scope_args+=(--agent "$skill_agent")
      done
      echo "ℹ Restricting skills install scope to detected agents: ''${skill_agents[*]}"
    else
      echo "ℹ No specific local agent config detected; using skills CLI default agent scope"
    fi

    detected_skill_agents_scope=""
    if [[ "''${#skill_agents[@]}" -gt 0 ]]; then
      detected_skill_agents_scope="''${skill_agents[*]}"
    fi

    desired_skill_state_json=${lib.escapeShellArg desiredSkillStateJson}
    desired_skill_state_hash=$(printf '%s\n%s' "$desired_skill_state_json" "$detected_skill_agents_scope" | ${pkgs.coreutils}/bin/sha256sum | cut -d' ' -f1)
    skill_state_cache_dir="$HOME/.cache/ai-agents"
    skill_state_cache_file="$skill_state_cache_dir/skills-state.sha256"
    skill_lock_file="$HOME/.agents/.skill-lock.json"
    skip_skill_install=0

    if [[ -f "$skill_state_cache_file" ]] && [[ -f "$skill_lock_file" ]]; then
      current_skill_state_hash="$(cat "$skill_state_cache_file")"
      if [[ "$current_skill_state_hash" == "$desired_skill_state_hash" ]]; then
        echo "✓ Skills configuration unchanged; skipping reinstall"
        skip_skill_install=1
      fi
    fi

    if [[ "$skip_skill_install" -eq 0 ]]; then
      attempt_cmd() {
        local label="$1"
        shift
        local attempt
        for attempt in 1 2 3; do
          if $DRY_RUN_CMD "$@"; then
            return 0
          fi
          echo "⚠ $label failed (attempt $attempt/3)"
          sleep 1
        done
        return 1
      }

      failed_installs=0
      successful_installs=0
      skipped_installs=0
      total_attempts=0
      processed_entries=0
      omit_failures=0
      configured_entries=${toString (builtins.length normalizedSkills)}
      install_started_epoch=$(date +%s)
      echo "📦 Installing agent skills from skills.sh (${toString (builtins.length normalizedSkills)} configured entries)..."
      echo "ℹ Running installs sequentially to avoid skills lock contention in global state"
      ${lib.concatStringsSep "" skillCommands}
      ${lib.optionalString (normalizedOmitSkills != [ ]) ''
        omit_total=${toString (builtins.length normalizedOmitSkills)}
        omit_processed=0
        echo "🧹 Removing omitted skills ($omit_total entries)..."
        ${lib.concatStringsSep "" omitCommands}
        if [[ "$omit_failures" -eq 0 ]]; then
          echo "✔ Omitted skills removal complete"
        fi
      ''}

      install_duration_seconds=$(( $(date +%s) - install_started_epoch ))

      echo "🧠 Skills summary: configured=$configured_entries processed=$processed_entries attempted=$total_attempts success=$successful_installs skipped=$skipped_installs omit_failures=$omit_failures failures=$failed_installs duration=''${install_duration_seconds}s"

      if [[ "$failed_installs" -gt 0 ]]; then
        echo "⚠ Skills installation finished with $failed_installs failures"
        echo "⚠ Continuing Home Manager activation; agent skills sync is best-effort"
      fi

      mkdir -p "$skill_state_cache_dir"
      printf '%s' "$desired_skill_state_hash" > "$skill_state_cache_file"

      echo "✓ Skills installation complete"
    fi

    if [[ -d "$HOME/.agents/skills" ]]; then
      disabled_dir="$HOME/.agents/skills.disabled-by-home-manager"
      if [[ ! -e "$disabled_dir" ]]; then
        echo "🧹 Disabling shared ~/.agents/skills tree to prevent OpenCode duplicate-skill spam"
        mv "$HOME/.agents/skills" "$disabled_dir"
      fi
    fi

    if [[ -d "$HOME/.claude/skills" ]]; then
      mkdir -p "$HOME/.codex/skills"
      find "$HOME/.codex/skills" -mindepth 1 -maxdepth 1 -type l -delete
      shopt -s nullglob
      for skill_dir in "$HOME/.claude/skills"/*; do
        [[ -d "$skill_dir" ]] || continue
        ln -sfn "$skill_dir" "$HOME/.codex/skills/$(basename "$skill_dir")"
      done
      shopt -u nullglob
      echo "✓ Mirrored Claude skills into ~/.codex/skills"
    fi
  ''
)
