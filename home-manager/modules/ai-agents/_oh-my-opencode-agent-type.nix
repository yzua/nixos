# Type definition for programs.aiAgents.opencode.ohMyOpencode.agents entries.
{ lib, ... }:

lib.types.attrsOf (
  lib.types.submodule {
    options = {
      model = lib.mkOption {
        type = lib.types.str;
        description = "Model to use for this agent";
      };
      variant = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Model variant (e.g., 'low', 'high', 'max')";
      };
      prompt = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "System prompt for this agent";
      };
      prompt_append = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Additional prompt appended to system prompt";
      };
      skills = lib.mkOption {
        type = lib.types.nullOr (lib.types.listOf lib.types.str);
        default = null;
        description = "Skills to enable (playwright, frontend-ui-ux, git-master)";
      };
      temperature = lib.mkOption {
        type = lib.types.nullOr lib.types.float;
        default = null;
        description = "Sampling temperature (0-2)";
      };
      top_p = lib.mkOption {
        type = lib.types.nullOr lib.types.float;
        default = null;
        description = "Top-p sampling (0-1)";
      };
      tools = lib.mkOption {
        type = lib.types.nullOr (lib.types.attrsOf lib.types.bool);
        default = null;
        description = "Enable/disable specific tools (e.g., { Edit = false; })";
      };
      description = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Agent description";
      };
      mode = lib.mkOption {
        type = lib.types.nullOr (
          lib.types.enum [
            "subagent"
            "primary"
            "all"
          ]
        );
        default = null;
        description = "Agent mode";
      };
      color = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Hex color for UI (e.g., '#FF5500')";
      };
      permission = lib.mkOption {
        type = lib.types.nullOr (
          lib.types.submodule {
            options = {
              edit = lib.mkOption {
                type = lib.types.nullOr (
                  lib.types.enum [
                    "ask"
                    "allow"
                    "deny"
                  ]
                );
                default = null;
              };
              bash = lib.mkOption {
                type = lib.types.nullOr (
                  lib.types.either
                    (lib.types.enum [
                      "ask"
                      "allow"
                      "deny"
                    ])
                    (
                      lib.types.attrsOf (
                        lib.types.enum [
                          "ask"
                          "allow"
                          "deny"
                        ]
                      )
                    )
                );
                default = null;
              };
              webfetch = lib.mkOption {
                type = lib.types.nullOr (
                  lib.types.enum [
                    "ask"
                    "allow"
                    "deny"
                  ]
                );
                default = null;
              };
              doom_loop = lib.mkOption {
                type = lib.types.nullOr (
                  lib.types.enum [
                    "ask"
                    "allow"
                    "deny"
                  ]
                );
                default = null;
              };
              external_directory = lib.mkOption {
                type = lib.types.nullOr (
                  lib.types.enum [
                    "ask"
                    "allow"
                    "deny"
                  ]
                );
                default = null;
              };
            };
          }
        );
        default = null;
        description = "Fine-grained permission settings";
      };
    };
  }
)
