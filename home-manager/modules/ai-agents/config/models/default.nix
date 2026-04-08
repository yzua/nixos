# Import hub for split model/provider configuration files.

{
  imports = [
    ./codex.nix # Codex CLI configuration
    ./gemini.nix # Gemini CLI configuration
    ./opencode.nix # OpenCode configuration
  ];

  # Shared AI agent toggles (not specific to any single agent).
  programs.aiAgents = {
    agencyAgents.enable = false;
    impeccable.enable = true;
  };
}
