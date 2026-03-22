# Type definition for programs.aiAgents.opencode.ohMyOpencode.agents entries.
{ lib, ... }:

let
  opt = import ./_option-helpers.nix { inherit lib; };
  inherit (opt) mkOptionNoDefault mkTypedOption mkNullOrOption;
  permissionStates = lib.types.enum [
    "ask"
    "allow"
    "deny"
  ];
in
lib.types.attrsOf (
  lib.types.submodule {
    options = {
      model = mkOptionNoDefault lib.types.str "Model to use for this agent";
      variant = mkNullOrOption lib.types.str "Model variant (e.g., 'low', 'high', 'max')";
      prompt = mkNullOrOption lib.types.str "System prompt for this agent";
      prompt_append = mkNullOrOption lib.types.str "Additional prompt appended to system prompt";
      skills = mkNullOrOption (lib.types.listOf lib.types.str) "Skills to enable (playwright, frontend-ui-ux, git-master)";
      temperature = mkNullOrOption lib.types.float "Sampling temperature (0-2)";
      top_p = mkNullOrOption lib.types.float "Top-p sampling (0-1)";
      tools = mkNullOrOption (lib.types.attrsOf lib.types.bool) "Enable/disable specific tools (e.g., { Edit = false; })";
      description = mkNullOrOption lib.types.str "Agent description";
      mode = mkNullOrOption (lib.types.enum [
        "subagent"
        "primary"
        "all"
      ]) "Agent mode";
      color = mkNullOrOption lib.types.str "Hex color for UI (e.g., '#FF5500')";
      permission = mkTypedOption (lib.types.nullOr (
        lib.types.submodule {
          options = {
            edit = mkTypedOption (lib.types.nullOr permissionStates) null "Edit permission mode";
            bash = mkTypedOption (lib.types.nullOr (
              lib.types.either permissionStates (lib.types.attrsOf permissionStates)
            )) null "Bash permission mode";
            webfetch = mkTypedOption (lib.types.nullOr permissionStates) null "Webfetch permission mode";
            doom_loop = mkTypedOption (lib.types.nullOr permissionStates) null "Doom loop permission mode";
            external_directory =
              mkTypedOption (lib.types.nullOr permissionStates) null
                "External directory permission mode";
          };
        }
      )) null "Fine-grained permission settings";
    };
  }
)
