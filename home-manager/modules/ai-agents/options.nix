# Option definitions for programs.aiAgents.

{
  config,
  lib,
  ...
}:

let
  opt = import ./_option-helpers.nix { inherit lib; };
  inherit (opt)
    mkTypedOption
    mkTypedOptionWith
    mkStrOption
    mkBoolOption
    mkIntOption
    mkAttrsOption
    mkAttrsOfStrOption
    mkStrListOption
    mkNullOrStrOption
    ;
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
      zaiApiKeyFile = mkNullOrStrOption "/run/secrets/zai_api_key" "Path to sops-decrypted Z.AI API key file";
      openrouterApiKeyFile = mkNullOrStrOption "/run/secrets/openrouter_api_key" "Path to sops-decrypted OpenRouter API key file";
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

    omitSkills = mkStrListOption [ ] "Installed skill names to remove after sync (global scope)";

    agencyAgents = {
      enable = mkBoolOption false "Install msitarzewski/agency-agents for Claude and OpenCode";
    };

    impeccable = {
      enable = mkBoolOption false "Install pbakaus/impeccable skills for Claude and OpenCode";
    };

    mcpServers = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            enable = mkBoolOption true "Enable this MCP server";
            type = mkTypedOption (lib.types.enum [
              "local"
              "remote"
            ]) "local" "Server type (local stdio or remote HTTP)";
            command = mkStrOption "" "Command to run for local servers";
            args = mkStrListOption [ ] "Arguments for the command";
            url = mkNullOrStrOption null "URL for remote MCP servers";
            headers = mkTypedOption (lib.types.nullOr (
              lib.types.attrsOf lib.types.str
            )) null "Headers for remote MCP servers";
            env = mkAttrsOfStrOption { } "Environment variables for the server";
          };
        }
      );
      default = { };
      description = "Shared MCP server definitions used by all agents";
    };

    logging = {
      enable = lib.mkEnableOption "centralized logging for AI agents";

      directory = mkStrOption "${config.xdg.dataHome}/ai-agents/logs" "Directory for AI agent logs";
      notifyOnError = mkBoolOption true "Send desktop notification on agent errors";
      enableOtel = mkBoolOption false "Enable OpenTelemetry for supported agents";
      otelEndpoint = mkStrOption "http://localhost:4317" "OpenTelemetry collector endpoint";
      otelExporter = mkStrOption "otlp" "OpenTelemetry exporter type";
      retentionDays = mkIntOption 30 "Days to retain log files";
    };

    # === Claude Options ===
    claude = {
      enable = lib.mkEnableOption "Claude Code configuration";

      model = mkStrOption "claude-sonnet-4-6" "Default model for Claude Code";
      env = mkAttrsOfStrOption { } "Environment variables for Claude Code";
      permissions = mkAttrsOption {
        allow = [ ];
        deny = [ ];
      } "Permission rules for Claude Code";
      hooks = mkAttrsOption { } "Lifecycle hooks for Claude Code";
      extraSettings = mkAttrsOption { } "Additional Claude Code settings";
    };

    # === OpenCode Options ===
    opencode = {
      enable = lib.mkEnableOption "OpenCode configuration";

      model = mkStrOption "anthropic/claude-sonnet-4-6" "Default model for OpenCode";
      plugins = mkStrListOption [ ] "OpenCode plugins to enable";
      providers = mkAttrsOption { } "Provider configurations for OpenCode";
      extraSettings = mkAttrsOption { } "Additional OpenCode settings";
    };

    # === Codex Options ===
    codex = {
      enable = lib.mkEnableOption "Codex CLI configuration";

      useWrapper = mkBoolOption true "Use logging wrapper for Codex";
      model = mkStrOption "gpt-5.4" "Default model for Codex";

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

      trustedProjects = mkStrListOption [ ] "Paths to projects with trust_level = trusted";

      extraToml = lib.mkOption {
        type = lib.types.lines;
        default = "";
        description = "Extra TOML lines appended to config.toml";
      };
    };

    # === Gemini Options ===
    gemini = {
      enable = lib.mkEnableOption "Gemini CLI configuration";

      theme = mkStrOption "Default" "Theme for Gemini CLI";
      sandboxMode = mkStrOption "cautious" "Sandbox mode (none, cautious, strict)";
      extraSettings = mkAttrsOption { } "Additional Gemini CLI settings";
    };
  };
}
