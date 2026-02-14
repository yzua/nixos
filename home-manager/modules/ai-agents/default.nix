# AI coding agents configuration (Claude Code, OpenCode, Codex, Gemini CLI).
{ ... }:
{
  imports = [
    ./options.nix # Option definitions for programs.aiAgents
    ./activation.nix # Activation scripts (secret patching, config setup, plugin installs)
    ./files.nix # home.file and xdg.configFile declarations
    ./services.nix # Packages, zsh aliases, systemd services/timers
    ./log-analyzer.nix # AI agent log analysis and dashboard
    ./config.nix # Actual agent configuration values
  ];
}
