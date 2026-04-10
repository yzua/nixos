# Codex configuration activation — generates ~/.codex/config.toml.

{
  cfg,
  pkgs,
  lib,
  sharedMcpServers,
}:
lib.mkIf cfg.codex.enable (
  let
    codexNotifyScript = pkgs.writeShellScript "codex-notify" ''
      set -euo pipefail

      payload=""
      for arg in "$@"; do
        if [[ -n "$arg" ]] && ${pkgs.jq}/bin/jq -e . >/dev/null 2>&1 <<< "$arg"; then
          payload="$arg"
          break
        fi
      done

      if [[ -z "$payload" ]]; then
        payload="$*"
      fi

      if [[ -z "$payload" ]] && [[ ! -t 0 ]]; then
        payload="$(cat)"
      fi

      summary="Codex"
      body="$payload"

      if [[ -n "$payload" ]] && ${pkgs.jq}/bin/jq -e . >/dev/null 2>&1 <<< "$payload"; then
        summary="$(${pkgs.jq}/bin/jq -r 'if type == "object" then (.title // .summary // "Codex") else "Codex" end' <<< "$payload")"
        body="$(${pkgs.jq}/bin/jq -r '
          if type == "object" then
            (.message // .body // ."last-assistant-message" // .content // .type // "Codex notification")
          else
            .
          end
        ' <<< "$payload")"
      fi

      body="$(printf '%s' "$body" | tr '\n' ' ')"
      body="$(printf '%s' "$body" | ${pkgs.gnused}/bin/sed -E 's/[[:space:]]+/ /g; s/^ //; s/ $//')"
      if [[ -z "$body" ]]; then
        body="Notification"
      fi

      notify-send -a "Codex" -i dialog-information "$summary" "$body" 2>/dev/null || true
    '';
    mcpToml = lib.concatStringsSep "\n" (
      lib.mapAttrsToList (
        name: server:
        let
          argsStr = lib.concatMapStringsSep ", " (a: ''"${a}"'') (server.args or [ ]);
          envSet = if (server.env or null) == null then { } else server.env;
          envLines = lib.concatStringsSep "\n" (lib.mapAttrsToList (k: v: ''${k} = "${v}"'') envSet);
        in
        ''
          [mcp_servers.${name}]
          command = "${server.command}"
          args = [${argsStr}]
          enabled = true
        ''
        + lib.optionalString (envSet != { }) ''

          [mcp_servers.${name}.env]
          ${envLines}
        ''
      ) (lib.filterAttrs (_: s: s.enable && (s.type or "local") == "local") sharedMcpServers)
    );
    projectsToml = lib.concatMapStringsSep "\n" (path: ''
      [projects."${path}"]
      trust_level = "trusted"
    '') cfg.codex.trustedProjects;
    featuresToml = lib.concatStringsSep "\n" (
      lib.mapAttrsToList (name: enabled: "${name} = ${lib.boolToString enabled}") cfg.codex.features
    );
    renderProfile =
      name: profile:
      let
        lines =
          lib.optional (profile.model != null) ''model = "${profile.model}"''
          ++ lib.optional (profile.personality != null) ''personality = "${profile.personality}"''
          ++ lib.optional (
            profile.reasoningEffort != null
          ) ''model_reasoning_effort = "${profile.reasoningEffort}"''
          ++ lib.optional (profile.approvalPolicy != null) ''approval_policy = "${profile.approvalPolicy}"''
          ++ lib.optional (profile.sandboxMode != null) ''sandbox_mode = "${profile.sandboxMode}"''
          ++ lib.optional (profile.developerInstructions != "") ''
            developer_instructions = """
            ${profile.developerInstructions}
            """
          ''
          ++ lib.optional (profile.extraToml != "") profile.extraToml;
      in
      ''
        [profiles.${name}]
        ${lib.concatStringsSep "\n" lines}
      '';
    profilesToml = lib.concatStringsSep "\n\n" (lib.mapAttrsToList renderProfile cfg.codex.profiles);
    renderCustomAgent =
      name: agent:
      let
        lines = [
          ''name = "${name}"''
          ''description = "${agent.description}"''
        ]
        ++ lib.optional (agent.model != null) ''model = "${agent.model}"''
        ++ lib.optional (
          agent.reasoningEffort != null
        ) ''model_reasoning_effort = "${agent.reasoningEffort}"''
        ++ lib.optional (agent.approvalPolicy != null) ''approval_policy = "${agent.approvalPolicy}"''
        ++ lib.optional (agent.sandboxMode != null) ''sandbox_mode = "${agent.sandboxMode}"''
        ++ [
          ''
            developer_instructions = """
            ${agent.developerInstructions}
            """
          ''
        ]
        ++ lib.optional (agent.extraToml != "") agent.extraToml;
      in
      ''
        cat > "$HOME/.codex/agents/${name}.toml" << 'CODEX_AGENT_EOF'
        ${lib.concatStringsSep "\n" lines}
        CODEX_AGENT_EOF
        ${pkgs.gnused}/bin/sed -i 's/^        //' "$HOME/.codex/agents/${name}.toml"
      '';
    customAgentsWrite = lib.concatStringsSep "\n" (
      lib.mapAttrsToList renderCustomAgent cfg.codex.customAgents
    );
  in
  lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.codex" "$HOME/.codex/agents"
    cat > "$HOME/.codex/config.toml" << 'CODEX_EOF'
    personality = "${cfg.codex.personality}"
    model = "${cfg.codex.model}"
    model_reasoning_effort = "${cfg.codex.reasoningEffort}"
    model_reasoning_summary = "concise"
    approval_policy = "${cfg.codex.approvalPolicy}"
    sandbox_mode = "${cfg.codex.sandboxMode}"
    allow_login_shell = false
    check_for_update_on_startup = true
    suppress_unstable_features_warning = true

    notify = ["${codexNotifyScript}"]

    developer_instructions = """
    Experienced developer. Concise communication, no preamble.
    Evidence-based decisions. Minimal changes - fix bugs without refactoring.
    Never suppress type errors. Never commit unless asked.
    Run diagnostics/tests on changed files before claiming done.
    Match existing codebase patterns and conventions.
    ${lib.optionalString (cfg.globalInstructions != "") cfg.globalInstructions}
    """

    [tui]
    animations = true
    notifications = true

    [history]
    persistence = "save-all"
    max_bytes = 52428800

    [features]
    ${featuresToml}

    ${mcpToml}
    ${projectsToml}
    ${profilesToml}

    [shell_environment_policy]
    inherit = "core"
    include_only = ["PATH", "HOME", "USER", "SHELL", "TERM", "EDITOR", "VISUAL", "LANG", "LC_ALL", "PWD"]
    exclude = ["AWS_*", "AZURE_*", "GCP_*", "ANTHROPIC_API_KEY", "OPENAI_API_KEY", "OPENROUTER_API_KEY"]

    ${cfg.codex.extraToml}
    CODEX_EOF
    ${pkgs.gnused}/bin/sed -i 's/^          //' "$HOME/.codex/config.toml"
    find "$HOME/.codex/agents" -maxdepth 1 -type f -name '*.toml' ! -name 'ecc-*.toml' -delete
    ${customAgentsWrite}
    echo "✓ Codex config.toml configured"
  ''
)
