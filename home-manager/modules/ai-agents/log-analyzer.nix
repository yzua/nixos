# AI agent log analyzer and dashboard.

{
  config,
  constants,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.aiAgents;
  scriptsDir = "${config.home.homeDirectory}/${constants.paths.scripts}";

  logAnalyzer = pkgs.writeShellScriptBin "ai-agent-analyze" ''
    AI_AGENT_LOG_DIR=${lib.escapeShellArg cfg.logging.directory} \
      exec ${scriptsDir}/ai/agent-analyze.sh "$@"
  '';

  logDashboard = pkgs.writeShellScriptBin "ai-agent-dashboard" ''
    AI_AGENT_LOG_DIR=${lib.escapeShellArg cfg.logging.directory} \
      exec ${scriptsDir}/ai/agent-dashboard.sh "$@"
  '';

in
{
  config = lib.mkIf (cfg.enable && cfg.logging.enable) {
    home.packages = [
      logAnalyzer
      logDashboard
    ];
  };
}
