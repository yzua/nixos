# Claude Code permissions, lifecycle hooks, and extra settings.

_:

let
  claudePermissionRules = import ./_claude-permission-rules.nix;
  claudeHooks = import ./_claude-hooks.nix;
in
{
  programs.aiAgents = {
    claude = {
      enable = true;
      model = "opus";

      env = {
        EDITOR = "nvim";
      };

      permissions = claudePermissionRules;
      hooks = claudeHooks;

      # === Extra Settings ===
      extraSettings = {
        cleanupPeriodDays = 14;
        respectGitignore = true;
        defaultMode = "bypassPermissions";
        skipDangerousModePermissionPrompt = true;
        alwaysThinkingEnabled = true;
        autoMemoryEnabled = true;
        includeGitInstructions = false;
        autoUpdatesChannel = "latest";
        attribution = {
          commit = "";
          pr = "";
        };
      };
    };
  };
}
