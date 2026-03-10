# Option definitions for programs.aiAgents.
{
  config,
  lib,
  ...
}:

let
  ohMyOpencodeAgentType = import ./_oh-my-opencode-agent-type.nix { inherit lib; };
in
{
  options.programs.aiAgents = {
    # === Core Options ===
    enable = lib.mkEnableOption "AI coding agents configuration";

    globalInstructions = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Global instructions injected into all AI agents (Claude CLAUDE.md, OpenCode instructions, Codex developer_instructions, Gemini systemInstruction)";
    };

    secrets = {
      zaiApiKeyFile = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = "/run/secrets/zai_api_key";
        description = "Path to sops-decrypted Z.AI API key file";
      };
    };

    skills = lib.mkOption {
      type = lib.types.listOf (
        lib.types.either lib.types.str (
          lib.types.submodule {
            options = {
              repo = lib.mkOption {
                type = lib.types.str;
                description = "GitHub repository (e.g., 'vercel-labs/skills')";
              };
              skill = lib.mkOption {
                type = lib.types.str;
                description = "Individual skill name from the repository";
              };
            };
          }
        )
      );
      default = [ ];
      description = ''
        List of skills to install from skills.sh.
        Use a string for repo-level installs (e.g., "obra/superpowers").
        Use an attrset { repo, skill } for individual skills
        (e.g., { repo = "vercel-labs/skills"; skill = "find-skills"; }).
      '';
      example = [
        "obra/superpowers"
        {
          repo = "vercel-labs/skills";
          skill = "find-skills";
        }
      ];
    };

    mcpServers = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            enable = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Enable this MCP server";
            };
            type = lib.mkOption {
              type = lib.types.enum [
                "local"
                "remote"
              ];
              default = "local";
              description = "Server type (local stdio or remote HTTP)";
            };
            command = lib.mkOption {
              type = lib.types.str;
              default = "";
              description = "Command to run for local servers";
            };
            args = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = "Arguments for the command";
            };
            url = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "URL for remote MCP servers";
            };
            headers = lib.mkOption {
              type = lib.types.nullOr (lib.types.attrsOf lib.types.str);
              default = null;
              description = "Headers for remote MCP servers";
            };
            env = lib.mkOption {
              type = lib.types.attrsOf lib.types.str;
              default = { };
              description = "Environment variables for the server";
            };
          };
        }
      );
      default = { };
      description = "Shared MCP server definitions used by all agents";
    };

    logging = {
      enable = lib.mkEnableOption "centralized logging for AI agents";

      directory = lib.mkOption {
        type = lib.types.str;
        default = "${config.xdg.dataHome}/ai-agents/logs";
        description = "Directory for AI agent logs";
      };

      notifyOnError = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Send desktop notification on agent errors";
      };

      enableOtel = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable OpenTelemetry for supported agents";
      };

      otelEndpoint = lib.mkOption {
        type = lib.types.str;
        default = "http://localhost:4317";
        description = "OpenTelemetry collector endpoint";
      };

      otelExporter = lib.mkOption {
        type = lib.types.str;
        default = "otlp";
        description = "OpenTelemetry exporter type";
      };

      retentionDays = lib.mkOption {
        type = lib.types.int;
        default = 30;
        description = "Days to retain log files";
      };
    };

    # === Claude Options ===
    claude = {
      enable = lib.mkEnableOption "Claude Code configuration";

      model = lib.mkOption {
        type = lib.types.str;
        default = "claude-sonnet-4-6";
        description = "Default model for Claude Code";
      };

      env = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = { };
        description = "Environment variables for Claude Code";
      };

      permissions = lib.mkOption {
        type = lib.types.attrs;
        default = {
          allow = [ ];
          deny = [ ];
        };
        description = "Permission rules for Claude Code";
      };

      hooks = lib.mkOption {
        type = lib.types.attrs;
        default = { };
        description = "Lifecycle hooks for Claude Code";
      };

      extraSettings = lib.mkOption {
        type = lib.types.attrs;
        default = { };
        description = "Additional Claude Code settings";
      };
    };

    # === OpenCode Options ===
    opencode = {
      enable = lib.mkEnableOption "OpenCode configuration";

      model = lib.mkOption {
        type = lib.types.str;
        default = "anthropic/claude-sonnet-4-6";
        description = "Default model for OpenCode";
      };

      plugins = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ "oh-my-opencode" ];
        description = "OpenCode plugins to enable";
      };

      providers = lib.mkOption {
        type = lib.types.attrs;
        default = { };
        description = "Provider configurations for OpenCode";
      };

      extraSettings = lib.mkOption {
        type = lib.types.attrs;
        default = { };
        description = "Additional OpenCode settings";
      };

      ohMyOpencode = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable oh-my-opencode configuration";
        };

        agents = lib.mkOption {
          type = ohMyOpencodeAgentType;
          default = { };
          description = "Agent configurations for oh-my-opencode";
          example = {
            sisyphus = {
              model = "anthropic/claude-opus-4-6";
              prompt = "You are Sisyphus, the relentless worker...";
              temperature = 0.7;
              permission = {
                edit = "allow";
                bash = "allow";
              };
            };
          };
        };

        extraSettings = lib.mkOption {
          type = lib.types.attrs;
          default = { };
          description = "Additional oh-my-opencode settings";
        };
      };
    };

    # === Codex Options ===
    codex = {
      enable = lib.mkEnableOption "Codex CLI configuration";

      useWrapper = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Use logging wrapper for Codex";
      };

      model = lib.mkOption {
        type = lib.types.str;
        default = "gpt-5.4";
        description = "Default model for Codex";
      };

      personality = lib.mkOption {
        type = lib.types.enum [
          "none"
          "friendly"
          "pragmatic"
        ];
        default = "pragmatic";
        description = "Model personality";
      };

      reasoningEffort = lib.mkOption {
        type = lib.types.enum [
          "none"
          "minimal"
          "low"
          "medium"
          "high"
          "xhigh"
        ];
        default = "medium";
        description = "Reasoning effort level";
      };

      approvalPolicy = lib.mkOption {
        type = lib.types.enum [
          "untrusted"
          "on-failure"
          "on-request"
          "never"
        ];
        default = "on-request";
        description = "Command approval policy";
      };

      trustedProjects = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Paths to projects with trust_level = trusted";
      };

      extraToml = lib.mkOption {
        type = lib.types.lines;
        default = "";
        description = "Extra TOML lines appended to config.toml";
      };
    };

    # === Gemini Options ===
    gemini = {
      enable = lib.mkEnableOption "Gemini CLI configuration";

      theme = lib.mkOption {
        type = lib.types.str;
        default = "Default";
        description = "Theme for Gemini CLI";
      };

      sandboxMode = lib.mkOption {
        type = lib.types.str;
        default = "cautious";
        description = "Sandbox mode (none, cautious, strict)";
      };

      extraSettings = lib.mkOption {
        type = lib.types.attrs;
        default = { };
        description = "Additional Gemini CLI settings";
      };
    };
  };
}
