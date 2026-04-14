# Plugin installation and cleanup — aggregates per-plugin modules.

# modules-check: manual-helper ./secrets.nix ./codex-setup.nix ./claude-setup.nix ./plugins.nix ./skills.nix

{
  cfg,
  config,
  pkgs,
  lib,
}:

let
  impeccable = import ./_plugin-impeccable.nix {
    inherit
      cfg
      config
      pkgs
      lib
      ;
  };
  agencyAgents = import ./_plugin-agency-agents.nix {
    inherit cfg pkgs lib;
  };
  everythingClaudeCode = import ./_plugin-everything-claude-code.nix {
    inherit
      cfg
      config
      pkgs
      lib
      ;
  };
  cleanupAgencyAgents = import ./_cleanup-agency-agents.nix {
    inherit cfg lib;
  };
  cleanupEverythingClaudeCode = import ./_cleanup-everything-claude-code.nix {
    inherit cfg config lib;
  };
in
impeccable
// agencyAgents
// everythingClaudeCode
// cleanupAgencyAgents
// cleanupEverythingClaudeCode
