# Import hub for split model/provider configuration files.

{
  imports = [
    ./codex.nix # Codex CLI configuration
    ./gemini.nix # Gemini CLI configuration
    ./omp.nix # oh-my-pi configuration
    ./opencode.nix # OpenCode configuration
  ];
}
