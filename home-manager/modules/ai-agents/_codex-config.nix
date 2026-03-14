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
  in
  lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.codex"
    cat > "$HOME/.codex/config.toml" << 'CODEX_EOF'
    personality = "${cfg.codex.personality}"
    model = "${cfg.codex.model}"
    model_reasoning_effort = "${cfg.codex.reasoningEffort}"
    model_reasoning_summary = "concise"
    approval_policy = "${cfg.codex.approvalPolicy}"
    allow_login_shell = false
    check_for_update_on_startup = true
    suppress_unstable_features_warning = true

    web_search = "cached"

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

    [profiles.quick]
    model_reasoning_effort = "low"

    [profiles.deep]
    model_reasoning_effort = "xhigh"
    approval_policy = "on-request"

    [profiles.safe]
    approval_policy = "untrusted"
    sandbox_mode = "read-only"

    [shell_environment_policy]
    inherit = "core"
    include_only = ["PATH", "HOME", "USER", "SHELL", "TERM", "EDITOR", "VISUAL", "LANG", "LC_ALL", "PWD"]
    exclude = ["AWS_*", "AZURE_*", "GCP_*", "ANTHROPIC_API_KEY", "OPENAI_API_KEY"]

    ${mcpToml}
    ${projectsToml}
    ${cfg.codex.extraToml}
    CODEX_EOF
    ${pkgs.gnused}/bin/sed -i 's/^          //' "$HOME/.codex/config.toml"
    echo "✓ Codex config.toml configured"
  ''
)
