# Packages, zsh aliases, systemd user services/timers, and log analysis for AI agents.

{
  aliasHelpers,
  config,
  constants,
  hmSystemdHelpers,
  lib,
  pkgs,
  secretLoader,
  ...
}:

let
  cfg = config.programs.aiAgents;
  scriptsDir = "${config.home.homeDirectory}/${constants.paths.scripts}";

  agentLogWrapper = pkgs.writeShellScriptBin "ai-agent-log-wrapper" ''
    AI_AGENT_LOG_DIR=${lib.escapeShellArg cfg.logging.directory} \
      AI_AGENT_NOTIFY_ON_ERROR=${if cfg.logging.notifyOnError then "true" else "false"} \
      exec ${scriptsDir}/ai/agent-log-wrapper.sh "$@"
  '';
  agentIter = pkgs.writeShellScriptBin "iter" (
    aliasLib.mkWorkflowEnvVars "bash ${scriptsDir}/ai/agent-iter.sh"
  );
  agentsSearch = pkgs.writeShellScriptBin "agents-search" ''
    exec ${scriptsDir}/ai/agents-search.sh "$@"
  '';
  logAnalyzer = pkgs.writeShellScriptBin "ai-agent-analyze" ''
    AI_AGENT_LOG_DIR=${lib.escapeShellArg cfg.logging.directory} \
      exec ${scriptsDir}/ai/agent-analyze.sh "$@"
  '';
  logDashboard = pkgs.writeShellScriptBin "ai-agent-dashboard" ''
    AI_AGENT_LOG_DIR=${lib.escapeShellArg cfg.logging.directory} \
      exec ${scriptsDir}/ai/agent-dashboard.sh "$@"
  '';
  androidReLaunchers = import ./helpers/_android-re-launchers.nix {
    inherit
      config
      constants
      lib
      pkgs
      scriptsDir
      secretLoader
      ;
  };

  aliasLib = import ./helpers/_aliases.nix {
    inherit
      lib
      pkgs
      scriptsDir
      ;
  };
  inherit (aliasLib) aiAliases aiAgentLauncher aiAgentInventory;
  mkCliAutoupdateScript = import ./helpers/_mk-cli-autoupdate-script.nix { inherit pkgs; };
  shellAliases = import ./helpers/_services-shell-aliases.nix {
    inherit cfg aiAliases constants;
  };

  logCleanupCommand = ''
    find "${cfg.logging.directory}" -name "*.log" -mtime +${toString cfg.logging.retentionDays} -delete
    find "$HOME/${constants.paths.opencodeLogDir}" -name "*.log" -mtime +${toString cfg.logging.retentionDays} -delete 2>/dev/null || true
    find "$HOME/${constants.paths.codexLogDir}" -name "*.log" -mtime +${toString cfg.logging.retentionDays} -delete 2>/dev/null || true
  '';

  aiSystemdUser = import ./helpers/_services-systemd.nix {
    inherit
      cfg
      config
      lib
      pkgs
      logCleanupCommand
      mkCliAutoupdateScript
      hmSystemdHelpers
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
    ))
    ++ (lib.optionals cfg.logging.enable [
      logAnalyzer
      logDashboard
    ]);

    home.sessionVariables = lib.mkIf cfg.opencode.enable {
      OPENCODE_EXPERIMENTAL_LSP_TOOL = "true";
    };

    programs = aliasHelpers { inherit shellAliases; };

    systemd.user = aiSystemdUser;
  };
}
