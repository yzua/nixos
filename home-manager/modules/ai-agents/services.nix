# Zsh aliases, systemd user services/timers, and packages for AI agents.

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.aiAgents;

  agentLogWrapper = pkgs.writeShellScriptBin "ai-agent-log-wrapper" ''
    AI_AGENT_LOG_DIR=${lib.escapeShellArg cfg.logging.directory} \
      AI_AGENT_NOTIFY_ON_ERROR=${if cfg.logging.notifyOnError then "true" else "false"} \
      exec ${config.home.homeDirectory}/System/scripts/ai/agent-log-wrapper.sh "$@"
  '';
  agentIter = pkgs.writeShellScriptBin "iter" ''
    COMMIT_SPLIT_PROMPT=${lib.escapeShellArg aliasLib.workflowPrompts.commitSplit} \
      REFACTOR_MAINTAINABILITY_PROMPT=${lib.escapeShellArg aliasLib.workflowPrompts.refactorMaintainability} \
      BUGFIX_ROOT_CAUSE_PROMPT=${lib.escapeShellArg aliasLib.workflowPrompts.bugfixRootCause} \
      SECURITY_AUDIT_PROMPT=${lib.escapeShellArg aliasLib.workflowPrompts.securityAudit} \
      DEPENDENCY_UPGRADE_PROMPT=${lib.escapeShellArg aliasLib.workflowPrompts.dependencyUpgrade} \
      BUILD_PERFORMANCE_PROMPT=${lib.escapeShellArg aliasLib.workflowPrompts.buildPerformance} \
      MARKDOWN_SYNC_PROMPT=${lib.escapeShellArg aliasLib.workflowPrompts.markdownSync} \
      exec bash ${config.home.homeDirectory}/System/scripts/ai/agent-iter.sh "$@"
  '';
  agentsSearch = pkgs.writeShellScriptBin "agents-search" ''
    exec ${config.home.homeDirectory}/System/scripts/ai/agents-search.sh "$@"
  '';
  androidReLaunchers = import ./helpers/_android-re-launchers.nix {
    inherit config lib pkgs;
  };

  aliasLib = import ./helpers/_aliases.nix { inherit config lib pkgs; };
  inherit (aliasLib) aiAliases aiAgentLauncher aiAgentInventory;
  mkCliAutoupdateScript = import ./helpers/_mk-cli-autoupdate-script.nix { inherit pkgs; };
  shellAliases = import ./helpers/_services-shell-aliases.nix {
    inherit cfg aiAliases;
  };

  logCleanupCommand = ''
    find "${cfg.logging.directory}" -name "*.log" -mtime +${toString cfg.logging.retentionDays} -delete
    find "$HOME/.local/share/opencode/log" -name "*.log" -mtime +${toString cfg.logging.retentionDays} -delete 2>/dev/null || true
    find "$HOME/.codex/log" -name "*.log" -mtime +${toString cfg.logging.retentionDays} -delete 2>/dev/null || true
  '';

  mkWeeklyTimer = description: {
    Unit.Description = description;
    Timer = {
      OnCalendar = "weekly";
      Persistent = true;
    };
    Install.WantedBy = [ "timers.target" ];
  };

  aiSystemdUser = import ./helpers/_services-systemd.nix {
    inherit
      cfg
      config
      lib
      pkgs
      logCleanupCommand
      mkCliAutoupdateScript
      mkWeeklyTimer
      ;
  };
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [
      agentLogWrapper
      agentIter
      agentsSearch
      aiAgentLauncher
      aiAgentInventory
      pkgs.bubblewrap
    ]
    ++ androidReLaunchers
    ++ (lib.optional cfg.logging.enable (
      pkgs.writeShellScriptBin "ai-agent-log-cleanup" ''
        ${logCleanupCommand}
        echo "Cleaned up logs older than ${toString cfg.logging.retentionDays} days"
      ''
    ));

    home.sessionVariables = lib.mkIf cfg.opencode.enable {
      OPENCODE_EXPERIMENTAL_LSP_TOOL = "true";
    };

    programs.zsh.shellAliases = shellAliases;
    programs.bash.shellAliases = shellAliases;

    systemd.user = aiSystemdUser;
  };
}
