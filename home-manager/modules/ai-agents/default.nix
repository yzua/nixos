# AI coding agents configuration (Claude Code, OpenCode, Codex, Gemini CLI).

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.aiAgents;

  inherit (builtins) toJSON;
  sharedMcpServers = cfg.mcpServers;

  claudeMcpServers = lib.mapAttrs (
    _: server:
    let
      isLocal = (server.type or "local") == "local";
    in
    if isLocal then
      {
        inherit (server) command;
        args = server.args or [ ];
        env = server.env or { };
      }
    else
      {
        type = "http";
        inherit (server) url;
      }
      // (lib.optionalAttrs (server.headers or null != null) { inherit (server) headers; })
  ) (lib.filterAttrs (_: s: s.enable) sharedMcpServers);

  opencodeMcpServers = lib.mapAttrs (
    _: server:
    let
      isLocal = (server.type or "local") == "local";
      base = {
        type = server.type or "local";
      };
      localAttrs = if isLocal then { command = [ server.command ] ++ (server.args or [ ]); } else { };
      remoteAttrs =
        if !isLocal then
          {
            inherit (server) url;
          }
          // (lib.optionalAttrs (server.headers or null != null) { inherit (server) headers; })
        else
          { };
      envAttrs = lib.optionalAttrs (server.env or { } != { }) { environment = server.env; };
    in
    base // localAttrs // remoteAttrs // envAttrs
  ) (lib.filterAttrs (_: s: s.enable) sharedMcpServers);

  geminiMcpServers = lib.mapAttrs (_: server: {
    inherit (server) command;
    args = server.args or [ ];
    env = server.env or { };
  }) (lib.filterAttrs (_: s: s.enable) sharedMcpServers);

  agentLogWrapper = pkgs.writeShellScriptBin "ai-agent-log-wrapper" ''
    #!/usr/bin/env bash

    AGENT_NAME="$1"
    shift

    LOG_DIR="${cfg.logging.directory}"
    LOG_FILE="$LOG_DIR/$AGENT_NAME-$(date +%Y-%m-%d).log"
    ERROR_LOG="$LOG_DIR/$AGENT_NAME-errors-$(date +%Y-%m-%d).log"

    mkdir -p "$LOG_DIR"

    echo "[$(date -Iseconds)] Starting $AGENT_NAME: $*" >> "$LOG_FILE"

    "$@" 2> >(tee -a "$ERROR_LOG" >&2) | tee -a "$LOG_FILE"
    EXIT_CODE=$?

    echo "[$(date -Iseconds)] $AGENT_NAME exited with code $EXIT_CODE" >> "$LOG_FILE"

    ${lib.optionalString cfg.logging.notifyOnError ''
      if [ $EXIT_CODE -ne 0 ]; then
        notify-send -u critical "AI Agent Error" "$AGENT_NAME failed with exit code $EXIT_CODE"
      fi
    ''}

    exit $EXIT_CODE
  '';

  claudeSettings = {
    inherit (cfg.claude) model permissions hooks;
    env =
      cfg.claude.env
      // (lib.optionalAttrs cfg.logging.enableOtel {
        CLAUDE_CODE_ENABLE_TELEMETRY = "1";
        OTEL_METRICS_EXPORTER = cfg.logging.otelExporter;
        OTEL_EXPORTER_OTLP_ENDPOINT = cfg.logging.otelEndpoint;
      });
  }
  // (lib.optionalAttrs (cfg.claude.extraSettings != { }) cfg.claude.extraSettings);

  opencodeSettings = {
    "$schema" = "https://opencode.ai/config.json";
    inherit (cfg.opencode) model;
    mcp = opencodeMcpServers;
    plugin = cfg.opencode.plugins;
    provider = cfg.opencode.providers;
  }
  // (lib.optionalAttrs (cfg.globalInstructions != "") { instructions = [ cfg.globalInstructions ]; })
  // (lib.optionalAttrs (cfg.opencode.extraSettings != { }) cfg.opencode.extraSettings);

  geminiSettings = {
    mcpServers = geminiMcpServers;
    inherit (cfg.gemini) theme sandboxMode;
  }
  // (lib.optionalAttrs (cfg.globalInstructions != "") {
    systemInstruction = cfg.globalInstructions;
  })
  // (lib.optionalAttrs (cfg.gemini.extraSettings != { }) cfg.gemini.extraSettings);

  ohMyOpencodeSettings = {
    "$schema" =
      "https://raw.githubusercontent.com/code-yeongyu/oh-my-opencode/master/assets/oh-my-opencode.schema.json";
    google_auth = cfg.opencode.ohMyOpencode.googleAuth;
    agents = lib.mapAttrs (
      _: agent:
      {
        inherit (agent) model;
      }
      // (lib.optionalAttrs (agent.variant != null) { inherit (agent) variant; })
      // (lib.optionalAttrs (agent.prompt != null) { inherit (agent) prompt; })
      // (lib.optionalAttrs (agent.prompt_append != null) { inherit (agent) prompt_append; })
      // (lib.optionalAttrs (agent.skills != null) { inherit (agent) skills; })
      // (lib.optionalAttrs (agent.temperature != null) { inherit (agent) temperature; })
      // (lib.optionalAttrs (agent.top_p != null) { inherit (agent) top_p; })
      // (lib.optionalAttrs (agent.tools != null) { inherit (agent) tools; })
      // (lib.optionalAttrs (agent.description != null) { inherit (agent) description; })
      // (lib.optionalAttrs (agent.mode != null) { inherit (agent) mode; })
      // (lib.optionalAttrs (agent.color != null) { inherit (agent) color; })
      // (lib.optionalAttrs (agent.permission != null) {
        permission = lib.filterAttrs (_: v: v != null) agent.permission;
      })
    ) cfg.opencode.ohMyOpencode.agents;
  }
  // (lib.optionalAttrs (
    cfg.opencode.ohMyOpencode.extraSettings != { }
  ) cfg.opencode.ohMyOpencode.extraSettings);

  # GLM-5 profile: Z.AI GLM models for cost-effective coding sessions.
  glmAgentModels = {
    sisyphus = "zai-coding-plan/glm-5";
    oracle = "zai-coding-plan/glm-5";
    librarian = "zai-coding-plan/glm-4.7";
    explore = "zai-coding-plan/glm-4.7-flash";
    # multimodal-looker keeps its original vision-capable model
    prometheus = "zai-coding-plan/glm-5";
    metis = "zai-coding-plan/glm-5";
    momus = "zai-coding-plan/glm-4.7";
    atlas = "zai-coding-plan/glm-4.7";
  };

  # Gemini profile: Google Antigravity models for Gemini-native coding sessions.
  geminiAgentModels = {
    sisyphus = "google/antigravity-gemini-3-pro";
    oracle = "google/antigravity-gemini-3-pro";
    librarian = "google/antigravity-gemini-3-flash";
    explore = "google/antigravity-gemini-3-flash";
    # multimodal-looker keeps its original vision-capable model
    prometheus = "google/antigravity-gemini-3-pro";
    metis = "google/antigravity-gemini-3-pro";
    momus = "google/antigravity-gemini-3-pro";
    atlas = "google/antigravity-gemini-3-flash";
    hephaestus = "google/antigravity-gemini-3-pro";
  };

  # Variant overrides for Gemini agents (thinking levels per role).
  geminiAgentVariants = {
    prometheus = "high"; # Strategic planning — max thinking
    momus = "low"; # Plan review — lighter thinking
    librarian = "medium"; # Reference search — moderate
    atlas = "medium"; # Coordination — moderate
    explore = "minimal"; # Fast grep — speed over depth
  };

  glmOpencodeSettings = opencodeSettings // {
    model = "zai-coding-plan/glm-5";
  };

  glmOhMyOpencodeSettings = ohMyOpencodeSettings // {
    agents =
      lib.mapAttrs (
        name: agentCfg:
        agentCfg
        // (lib.optionalAttrs (builtins.hasAttr name glmAgentModels) {
          model = glmAgentModels.${name};
        })
      ) ohMyOpencodeSettings.agents
      // {
        # Autonomous deep worker agent (defaults to gpt-5.3-codex)
        hephaestus = {
          model = "zai-coding-plan/glm-5";
        };
      };

    # Override category models to use GLM instead of default providers
    categories = {
      "visual-engineering" = {
        model = "zai-coding-plan/glm-5";
      };
      ultrabrain = {
        model = "zai-coding-plan/glm-5";
      };
      deep = {
        model = "zai-coding-plan/glm-5";
      };
      artistry = {
        model = "zai-coding-plan/glm-5";
      };
      quick = {
        model = "zai-coding-plan/glm-4.7-flash";
      };
      "unspecified-low" = {
        model = "zai-coding-plan/glm-4.7";
      };
      "unspecified-high" = {
        model = "zai-coding-plan/glm-5";
      };
      writing = {
        model = "zai-coding-plan/glm-4.7";
      };
    };
  };

  # Gemini profile: Google Antigravity models for Gemini-native coding sessions.
  geminiOpencodeSettings = opencodeSettings // {
    model = "google/antigravity-gemini-3-pro";
  };

  geminiOhMyOpencodeSettings = ohMyOpencodeSettings // {
    agents = lib.mapAttrs (
      name: agentCfg:
      agentCfg
      // (lib.optionalAttrs (builtins.hasAttr name geminiAgentModels) {
        model = geminiAgentModels.${name};
      })
      // (lib.optionalAttrs (builtins.hasAttr name geminiAgentVariants) {
        variant = geminiAgentVariants.${name};
      })
    ) ohMyOpencodeSettings.agents;

    # Override category models to use Gemini Antigravity instead of default providers
    categories = {
      "visual-engineering" = {
        model = "google/antigravity-gemini-3-pro";
      };
      ultrabrain = {
        model = "google/antigravity-gemini-3-pro";
        variant = "high";
      };
      deep = {
        model = "google/antigravity-gemini-3-pro";
        variant = "high";
      };
      artistry = {
        model = "google/antigravity-gemini-3-pro";
      };
      quick = {
        model = "google/antigravity-gemini-3-flash";
        variant = "minimal";
      };
      "unspecified-low" = {
        model = "google/antigravity-gemini-3-flash";
        variant = "medium";
      };
      "unspecified-high" = {
        model = "google/antigravity-gemini-3-pro";
        variant = "high";
      };
      writing = {
        model = "google/antigravity-gemini-3-flash";
        variant = "medium";
      };
    };
  };

in
{
  imports = [
    ./log-analyzer.nix
    ./config.nix
  ];

  options.programs.aiAgents = {
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
        default = "${config.home.homeDirectory}/.local/share/ai-agents/logs";
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

    claude = {
      enable = lib.mkEnableOption "Claude Code configuration";

      model = lib.mkOption {
        type = lib.types.str;
        default = "claude-sonnet-4-5-20250514";
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

    opencode = {
      enable = lib.mkEnableOption "OpenCode configuration";

      model = lib.mkOption {
        type = lib.types.str;
        default = "anthropic/claude-sonnet-4-5";
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

        googleAuth = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Use Google OAuth for authentication";
        };

        agents = lib.mkOption {
          type = lib.types.attrsOf (
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
          );
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

    codex = {
      enable = lib.mkEnableOption "Codex CLI configuration";

      useWrapper = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Use logging wrapper for Codex";
      };

      model = lib.mkOption {
        type = lib.types.str;
        default = "gpt-5.3-codex";
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

  config = lib.mkIf cfg.enable {
    home = {
      packages = [
        agentLogWrapper
        pkgs.tmux
        pkgs.zig
        pkgs.rustfmt
      ]
      ++ (lib.optional cfg.logging.enable (
        pkgs.writeShellScriptBin "ai-agent-log-cleanup" ''
          find "${cfg.logging.directory}" -name "*.log" -mtime +${toString cfg.logging.retentionDays} -delete
          echo "Cleaned up logs older than ${toString cfg.logging.retentionDays} days"
        ''
      ));

      activation = {
        # Runs after setupCodexConfig so keys can be injected.
        patchAiAgentSecrets = lib.mkIf (cfg.secrets.zaiApiKeyFile != null) (
          lib.hm.dag.entryAfter [ "writeBoundary" "linkGeneration" "setupCodexConfig" ] ''
            if [[ -f "${cfg.secrets.zaiApiKeyFile}" ]]; then
              ZAI_KEY="$(cat "${cfg.secrets.zaiApiKeyFile}")"
              
              for OPENCODE_CFG in "$HOME/.config/opencode/opencode.json" "$HOME/.config/opencode-glm/opencode.json" "$HOME/.config/opencode-gemini/opencode.json"; do
                if [[ -f "$OPENCODE_CFG" ]]; then
                  ${pkgs.jq}/bin/jq --arg key "$ZAI_KEY" '
                    .mcp["zai-mcp-server"].environment.Z_AI_API_KEY = $key |
                    .mcp["web-search-prime"] = {
                      type: "remote",
                      url: "https://api.z.ai/api/mcp/web_search_prime/mcp",
                      headers: { Authorization: ("Bearer " + $key) }
                    } |
                    .mcp["web-reader"] = {
                      type: "remote",
                      url: "https://api.z.ai/api/mcp/web_reader/mcp",
                      headers: { Authorization: ("Bearer " + $key) }
                    } |
                    .mcp["zread"] = {
                      type: "remote",
                      url: "https://api.z.ai/api/mcp/zread/mcp",
                      headers: { Authorization: ("Bearer " + $key) }
                    }
                  ' "$OPENCODE_CFG" > "$OPENCODE_CFG.tmp" && mv "$OPENCODE_CFG.tmp" "$OPENCODE_CFG"
                  echo "✓ Patched $(basename "$(dirname "$OPENCODE_CFG")")/opencode.json with Z.AI API key"
                fi
              done
              
              CLAUDE_MCP="$HOME/.mcp.json"
              if [[ -f "$CLAUDE_MCP" ]]; then
                ${pkgs.jq}/bin/jq --arg key "$ZAI_KEY" '
                  .mcpServers["zai-mcp-server"].env.Z_AI_API_KEY = $key |
                  .mcpServers["web-search-prime"] = {
                    type: "http",
                    url: "https://api.z.ai/api/mcp/web_search_prime/mcp",
                    headers: { Authorization: ("Bearer " + $key) }
                  } |
                  .mcpServers["web-reader"] = {
                    type: "http",
                    url: "https://api.z.ai/api/mcp/web_reader/mcp",
                    headers: { Authorization: ("Bearer " + $key) }
                  } |
                  .mcpServers["zread"] = {
                    type: "http",
                    url: "https://api.z.ai/api/mcp/zread/mcp",
                    headers: { Authorization: ("Bearer " + $key) }
                  }
                ' "$CLAUDE_MCP" > "$CLAUDE_MCP.tmp" && mv "$CLAUDE_MCP.tmp" "$CLAUDE_MCP"
                echo "✓ Patched .mcp.json with Z.AI API key + remote MCPs"
              fi

              CODEX_CFG="$HOME/.codex/config.toml"
              if [[ -f "$CODEX_CFG" ]]; then
                if grep -q '\[mcp_servers.zai-mcp-server.env\]' "$CODEX_CFG"; then
                  ESCAPED_ZAI=$(printf '%s\n' "$ZAI_KEY" | ${pkgs.gnused}/bin/sed 's/[&/\]/\\&/g')
                  ${pkgs.gnused}/bin/sed -i "/\[mcp_servers.zai-mcp-server.env\]/a Z_AI_API_KEY = \"$ESCAPED_ZAI\"" "$CODEX_CFG"
                  unset ESCAPED_ZAI
                fi
                echo "✓ Patched codex config.toml with Z.AI API key"
              fi

              GEMINI_CFG="$HOME/.gemini/settings.json"
              if [[ -f "$GEMINI_CFG" ]]; then
                ${pkgs.jq}/bin/jq --arg key "$ZAI_KEY" '
                  .mcpServers["zai-mcp-server"].env.Z_AI_API_KEY = $key |
                  .mcpServers["web-search-prime"] = {
                    command: "echo",
                    args: [],
                    url: "https://api.z.ai/api/mcp/web_search_prime/mcp",
                    headers: { Authorization: ("Bearer " + $key) },
                    type: "http"
                  } |
                  .mcpServers["web-reader"] = {
                    command: "echo",
                    args: [],
                    url: "https://api.z.ai/api/mcp/web_reader/mcp",
                    headers: { Authorization: ("Bearer " + $key) },
                    type: "http"
                  }
                ' "$GEMINI_CFG" > "$GEMINI_CFG.tmp" && mv "$GEMINI_CFG.tmp" "$GEMINI_CFG"
                echo "✓ Patched gemini settings.json with Z.AI API key + remote MCPs"
              fi
            else
              echo "⚠ ${cfg.secrets.zaiApiKeyFile} not found - run 'just nixos' first"
            fi

            # Inject GitHub token from gh CLI into all agent configs
            if command -v gh &> /dev/null && gh auth status &> /dev/null; then
              GH_TOKEN="$(gh auth token)"
              # SECURITY: Use jq for JSON files (safe handling of special chars in tokens)
              for OPENCODE_CFG in "$HOME/.config/opencode/opencode.json" "$HOME/.config/opencode-glm/opencode.json" "$HOME/.config/opencode-gemini/opencode.json"; do
                if [[ -f "$OPENCODE_CFG" ]]; then
                  ${pkgs.jq}/bin/jq --arg token "$GH_TOKEN" '
                    walk(if type == "string" then gsub("__GITHUB_TOKEN_PLACEHOLDER__"; $token) else . end)
                  ' "$OPENCODE_CFG" > "$OPENCODE_CFG.tmp" && mv "$OPENCODE_CFG.tmp" "$OPENCODE_CFG"
                fi
              done
              if [[ -f "$HOME/.mcp.json" ]]; then
                ${pkgs.jq}/bin/jq --arg token "$GH_TOKEN" '
                  walk(if type == "string" then gsub("__GITHUB_TOKEN_PLACEHOLDER__"; $token) else . end)
                ' "$HOME/.mcp.json" > "$HOME/.mcp.json.tmp" && mv "$HOME/.mcp.json.tmp" "$HOME/.mcp.json"
              fi
              if [[ -f "$HOME/.codex/config.toml" ]]; then
                ESCAPED_TOKEN=$(printf '%s\n' "$GH_TOKEN" | ${pkgs.gnused}/bin/sed 's/[&/\]/\\&/g')
                ${pkgs.gnused}/bin/sed -i "s/__GITHUB_TOKEN_PLACEHOLDER__/$ESCAPED_TOKEN/g" "$HOME/.codex/config.toml"
              fi
              if [[ -f "$HOME/.gemini/settings.json" ]]; then
                ${pkgs.jq}/bin/jq --arg token "$GH_TOKEN" '
                  walk(if type == "string" then gsub("__GITHUB_TOKEN_PLACEHOLDER__"; $token) else . end)
                ' "$HOME/.gemini/settings.json" > "$HOME/.gemini/settings.json.tmp" && mv "$HOME/.gemini/settings.json.tmp" "$HOME/.gemini/settings.json"
              fi
              unset GH_TOKEN
              echo "✓ Patched GitHub token from gh CLI into all agent configs"
            else
              echo "⚠ gh CLI not authenticated - GitHub MCP will not work (run 'gh auth login')"
            fi
          ''
        );

        installAgentSkills =
          let
            # Pre-generate install commands at Nix eval time
            skillCommands = map (
              s:
              if builtins.isString s then
                # Repo-level: skills add "owner/repo" --global --all --yes
                ''
                  echo "  → ${s}"
                  $DRY_RUN_CMD "$SKILLS_BIN" add "${s}" --global --all --yes 2>&1 | tail -1 || true
                ''
              else
                # Individual: skills add https://github.com/owner/repo --skill name --global --all --yes
                ''
                  echo "  → ${s.repo}#${s.skill}"
                  $DRY_RUN_CMD "$SKILLS_BIN" add "https://github.com/${s.repo}" --skill "${s.skill}" --global --all --yes 2>&1 | tail -1 || true
                ''
            ) cfg.skills;
          in
          lib.mkIf (cfg.skills != [ ]) (
            lib.hm.dag.entryAfter [ "writeBoundary" ] ''
              SKILLS_BIN="$HOME/.bun/bin/skills"
              if [[ ! -x "$SKILLS_BIN" ]]; then
                SKILLS_BIN="$(command -v skills 2>/dev/null || true)"
              fi
              if [[ -n "$SKILLS_BIN" ]]; then
                echo "📦 Installing agent skills from skills.sh..."
                ${lib.concatStringsSep "" skillCommands}
                echo "✓ Skills installation complete"
              else
                echo "⚠ skills CLI not found — run 'bun install -g skills' first"
              fi
            ''
          );

        setupCodexConfig = lib.mkIf cfg.codex.enable (
          let
            mcpToml = lib.concatStringsSep "\n" (
              lib.mapAttrsToList (
                name: server:
                let
                  argsStr = lib.concatMapStringsSep ", " (a: ''"${a}"'') (server.args or [ ]);
                  envLines = lib.concatStringsSep "\n" (
                    lib.mapAttrsToList (k: v: ''${k} = "${v}"'') (server.env or { })
                  );
                in
                ''
                  [mcp_servers.${name}]
                  command = "${server.command}"
                  args = [${argsStr}]
                  enabled = true
                ''
                + lib.optionalString (server.env or { } != { }) ''
                  [mcp_servers.${name}.env]
                  ${envLines}
                ''
              ) (lib.filterAttrs (_: s: s.enable) sharedMcpServers)
            );
            projectsToml = lib.concatMapStringsSep "\n" (path: ''
              [projects."${path}"]
              trust_level = "trusted"
            '') cfg.codex.trustedProjects;
          in
          lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            mkdir -p "$HOME/.codex"
            cat > "$HOME/.codex/config.toml" << 'CODEX_EOF'
            personality = "${cfg.codex.personality}"
            model = "${cfg.codex.model}"
            model_reasoning_effort = "${cfg.codex.reasoningEffort}"
            approval_policy = "${cfg.codex.approvalPolicy}"
            check_for_update_on_startup = true

            web_search = "live"

            notify = ["notify-send", "Codex"]

            developer_instructions = """
            Experienced developer. Concise communication, no preamble.
            Evidence-based decisions. Minimal changes - fix bugs without refactoring.
            Never suppress type errors. Never commit unless asked.
            Run diagnostics/tests on changed files before claiming done.
            Match existing codebase patterns and conventions.
            ${lib.optionalString (cfg.globalInstructions != "") cfg.globalInstructions}
            """

            [tui]
            animations = true
            notifications = true

            [history]
            persistence = "save-all"

            [profiles.quick]
            model_reasoning_effort = "low"
            approval_policy = "on-failure"

            [profiles.deep]
            model_reasoning_effort = "xhigh"
            approval_policy = "on-request"

            [profiles.safe]
            approval_policy = "untrusted"
            sandbox_mode = "read-only"

            [shell_environment_policy]
            inherit = "core"
            exclude = ["AWS_*", "AZURE_*", "GCP_*", "ANTHROPIC_API_KEY", "OPENAI_API_KEY"]

            [sandbox_workspace_write]
            network_access = true
            writable_roots = ["/home/yz/.config", "/home/yz/.local"]

            ${mcpToml}
            ${projectsToml}
            ${cfg.codex.extraToml}
            CODEX_EOF
            ${pkgs.gnused}/bin/sed -i 's/^            //' "$HOME/.codex/config.toml"
            echo "✓ Codex config.toml configured"
          ''
        );

        # Real files (not symlinks) so plugins can modify them.
        setupClaudeConfig = lib.mkIf cfg.claude.enable (
          let
            claudeSettingsFile = pkgs.writeText "claude-settings.json" (toJSON claudeSettings);
            claudeMcpFile = pkgs.writeText "claude-mcp.json" (toJSON {
              mcpServers = claudeMcpServers;
            });
          in
          lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            mkdir -p "$HOME/.claude"

            CLAUDE_SETTINGS="$HOME/.claude/settings.json"

            if [[ -f "$CLAUDE_SETTINGS" ]] && [[ ! -L "$CLAUDE_SETTINGS" ]]; then
              ${pkgs.jq}/bin/jq -s '.[0] * .[1]' "$CLAUDE_SETTINGS" "${claudeSettingsFile}" > "$CLAUDE_SETTINGS.tmp"
              mv "$CLAUDE_SETTINGS.tmp" "$CLAUDE_SETTINGS"
            else
              rm -f "$CLAUDE_SETTINGS"
              cp "${claudeSettingsFile}" "$CLAUDE_SETTINGS"
              chmod 644 "$CLAUDE_SETTINGS"
            fi
            echo "✓ Claude settings.json configured"

            CLAUDE_MCP="$HOME/.mcp.json"

            if [[ -f "$CLAUDE_MCP" ]] && [[ ! -L "$CLAUDE_MCP" ]]; then
              ${pkgs.jq}/bin/jq -s '.[0] * .[1]' "$CLAUDE_MCP" "${claudeMcpFile}" > "$CLAUDE_MCP.tmp"
              mv "$CLAUDE_MCP.tmp" "$CLAUDE_MCP"
            else
              rm -f "$CLAUDE_MCP"
              cp "${claudeMcpFile}" "$CLAUDE_MCP"
              chmod 644 "$CLAUDE_MCP"
            fi
            echo "✓ Claude .mcp.json configured"

            ${lib.optionalString (cfg.globalInstructions != "") ''
                CLAUDE_MD="$HOME/.claude/CLAUDE.md"
                cat > "$CLAUDE_MD" << 'CLAUDE_INSTRUCTIONS_EOF'
              ${cfg.globalInstructions}
              CLAUDE_INSTRUCTIONS_EOF
                ${pkgs.gnused}/bin/sed -i 's/^            //' "$CLAUDE_MD"
                echo "✓ Claude CLAUDE.md configured"
            ''}
          ''
        );

        installOhMyClaudeCode = lib.mkIf cfg.claude.enable (
          lib.hm.dag.entryAfter [ "setupClaudeConfig" ] ''
            if command -v claude &> /dev/null; then
              if ! claude plugin marketplace list 2>/dev/null | grep -q "omc"; then
                echo "📦 Adding oh-my-claudecode marketplace..."
                claude plugin marketplace add https://github.com/Yeachan-Heo/oh-my-claudecode 2>/dev/null || true
              fi
              
              if ! claude plugin list 2>/dev/null | grep -q "oh-my-claudecode"; then
                echo "📦 Installing oh-my-claudecode plugin..."
                claude plugin install oh-my-claudecode@omc 2>/dev/null || true
              fi
              echo "✓ oh-my-claudecode ready"
            fi
          ''
        );

        installEverythingClaudeCode = lib.mkIf cfg.claude.enable (
          lib.hm.dag.entryAfter [ "setupClaudeConfig" ] ''
            ECC_DIR="$HOME/.local/share/everything-claude-code"

            if command -v claude &> /dev/null; then
              if [[ -d "$ECC_DIR/.git" ]]; then
                echo "📦 Updating everything-claude-code..."
                ${pkgs.git}/bin/git -C "$ECC_DIR" pull --ff-only 2>/dev/null || true
              else
                echo "📦 Cloning everything-claude-code..."
                rm -rf "$ECC_DIR"
                ${pkgs.git}/bin/git clone --depth 1 https://github.com/affaan-m/everything-claude-code.git "$ECC_DIR" 2>/dev/null || true
              fi

              if ! claude plugin marketplace list 2>/dev/null | grep -q "everything-claude-code"; then
                echo "📦 Adding everything-claude-code marketplace..."
                claude plugin marketplace add affaan-m/everything-claude-code 2>/dev/null || true
              fi

              if ! claude plugin list 2>/dev/null | grep -q "everything-claude-code"; then
                echo "📦 Installing everything-claude-code plugin..."
                claude plugin install everything-claude-code@everything-claude-code 2>/dev/null || true
              fi

              if [[ -d "$ECC_DIR/rules" ]]; then
                mkdir -p "$HOME/.claude/rules"
                if [[ -d "$ECC_DIR/rules/common" ]]; then
                  cp -r "$ECC_DIR/rules/common/"* "$HOME/.claude/rules/" 2>/dev/null || true
                fi
                if [[ -d "$ECC_DIR/rules/typescript" ]]; then
                  cp -r "$ECC_DIR/rules/typescript/"* "$HOME/.claude/rules/" 2>/dev/null || true
                fi
                if [[ -d "$ECC_DIR/rules/python" ]]; then
                  cp -r "$ECC_DIR/rules/python/"* "$HOME/.claude/rules/" 2>/dev/null || true
                fi
                if [[ -d "$ECC_DIR/rules/golang" ]]; then
                  cp -r "$ECC_DIR/rules/golang/"* "$HOME/.claude/rules/" 2>/dev/null || true
                fi
                echo "✓ Installed ECC rules (common + typescript + python + golang)"
              fi

              echo "✓ everything-claude-code ready"
            fi
          ''
        );
      };

      file = lib.mkMerge [
        (lib.mkIf cfg.gemini.enable {
          ".gemini/settings.json" = {
            text = toJSON geminiSettings;
            force = true;
          };

          ".gemini/skills/code-reviewer/SKILL.md" = {
            text = ''
              ---
              name: code-reviewer
              description: Review code for quality, security, and best practices. Use when asked to review code, PRs, or diffs.
              ---

              # Code Reviewer

              ## When to Activate
              - User asks to review code, a PR, or a diff
              - User asks "is this code good?" or "any issues with this?"

              ## Review Checklist
              1. **Correctness**: Does the logic do what it claims?
              2. **Edge cases**: Missing null checks, empty arrays, boundary conditions
              3. **Security**: SQL injection, XSS, hardcoded secrets, unsafe deserialization
              4. **Performance**: N+1 queries, unnecessary allocations, missing indexes
              5. **Maintainability**: Clear naming, reasonable function size, no dead code
              6. **Error handling**: Are errors caught? Are error messages useful?
              7. **Tests**: Are critical paths tested? Are edge cases covered?

              ## Output Format
              - Rate severity: 🔴 Critical | 🟡 Warning | 🟢 Suggestion
              - Be specific: include file path and line number
              - Suggest fixes, not just problems
              - Acknowledge what's done well (briefly)

              ## Style
              - Concise, no fluff
              - Group by file
              - Most critical issues first
            '';
          };

          ".gemini/skills/nix-helper/SKILL.md" = {
            text = ''
              ---
              name: nix-helper
              description: Help with NixOS configuration, Nix expressions, and flake management.
              ---

              # Nix Helper

              ## When to Activate
              - User asks about NixOS configuration
              - Working with .nix files
              - Flake management questions

              ## Key Patterns
              1. **Module pattern**: `{ config, lib, pkgs, ... }: { options = ...; config = ...; }`
              2. **Package list**: `environment.systemPackages = with pkgs; [ ... ]`
              3. **Enable pattern**: `lib.mkEnableOption "description"`
              4. **Conditional**: `lib.mkIf config.mySystem.feature.enable { ... }`

              ## Validation Pipeline
              ```bash
              just modules   # Check imports
              just lint      # statix + deadnix
              just format    # nixfmt-tree
              just check     # nix flake check
              just home      # Apply (safe)
              just nixos     # Apply (system)
              ```

              ## Common Fixes
              - Missing import → add to parent default.nix
              - deadnix warning → remove unused or prefix with _
              - statix suggestion → apply directly
            '';
          };

          ".gemini/skills/pr-creator/SKILL.md" = {
            text = ''
              ---
              name: pr-creator
              description: Create well-structured pull requests with clear descriptions. Use when asked to create a PR or prepare changes for review.
              ---

              # PR Creator

              ## When to Activate
              - User asks to create a PR or prepare changes for review
              - User says "submit this" or "make a PR"

              ## PR Structure
              1. **Title**: Concise, imperative mood ("Add auth middleware", not "Added auth middleware")
              2. **Summary**: 1-3 bullet points of what changed and why
              3. **Type**: Feature | Fix | Refactor | Docs | Chore
              4. **Testing**: What was tested and how
              5. **Breaking changes**: List any, or "None"

              ## Workflow
              1. Review all uncommitted changes (`git diff`, `git status`)
              2. Group related changes into logical commits
              3. Write commit messages (conventional commits style)
              4. Create PR with `gh pr create`
              5. Add appropriate labels if available

              ## Commit Message Format
              ```
              type(scope): brief description

              Longer explanation if needed.
              ```
              Types: feat, fix, refactor, docs, test, chore, perf

              ## Rules
              - Never include unrelated changes
              - Never commit secrets, .env files, or credentials
              - Always run project lint/test before creating PR
              - Draft PR if work is incomplete
            '';
          };
          # Aider configuration
          ".aider.conf.yml".text = builtins.toJSON {
            model = "claude-sonnet-4-5";
            editor-model = "claude-haiku-4-5";
            auto-commits = false;
            dirty-commits = false;
            attribute-author = false;
            attribute-committer = false;
            dark-mode = true;
            pretty = true;
            stream = true;
            map-tokens = 2048;
            map-refresh = "auto";
            auto-lint = true;
            lint-cmd = "just lint";
            auto-test = false;
            test-cmd = "just check";
            suggest-shell-commands = false;
          };
        })
      ];
    };

    xdg.configFile = lib.mkIf cfg.opencode.enable {
      "opencode/opencode.json" = {
        text = toJSON opencodeSettings;
        force = true;
      };
      "opencode/oh-my-opencode.json" = lib.mkIf cfg.opencode.ohMyOpencode.enable {
        text = toJSON ohMyOpencodeSettings;
        force = true;
      };

      # GLM-5 profile (used by ocg via OPENCODE_CONFIG_DIR)
      "opencode-glm/opencode.json" = {
        text = toJSON glmOpencodeSettings;
        force = true;
      };
      "opencode-glm/oh-my-opencode.json" = lib.mkIf cfg.opencode.ohMyOpencode.enable {
        text = toJSON glmOhMyOpencodeSettings;
        force = true;
      };

      # Gemini Antigravity profile (used by ocgem via OPENCODE_CONFIG_DIR)
      "opencode-gemini/opencode.json" = {
        text = toJSON geminiOpencodeSettings;
        force = true;
      };
      "opencode-gemini/oh-my-opencode.json" = lib.mkIf cfg.opencode.ohMyOpencode.enable {
        text = toJSON geminiOhMyOpencodeSettings;
        force = true;
      };
    };

    programs.zsh.shellAliases = lib.mkIf cfg.logging.enable {
      "cl-log" = "ai-agent-log-wrapper claude claude";
      "oc-log" = "ai-agent-log-wrapper opencode opencode";
      "codex-log" = "ai-agent-log-wrapper codex codex";
      "gemini-log" = "ai-agent-log-wrapper gemini gemini";

      "ai-logs" = "tail -f ~/.local/share/opencode/log/*.log ~/.codex/log/*.log 2>/dev/null";
      "ai-errors" =
        "grep -rn --color=always -i 'error\\|panic\\|fatal\\|exception' ~/.local/share/opencode/log/ ~/.codex/log/ 2>/dev/null | tail -50";

      "ai-stats" = "ai-agent-analyze stats";
      "ai-report" = "ai-agent-analyze report";
      "ai-dash" = "ai-agent-dashboard";
    };

    systemd.user = lib.mkIf cfg.logging.enable {
      # Create log directory declaratively (replaces createAiAgentLogDir activation script)
      tmpfiles.rules = [
        "d ${cfg.logging.directory} 0755 - - -"
      ];

      services.ai-agent-log-cleanup = {
        Unit.Description = "Clean up old AI agent logs";
        Service = {
          Type = "oneshot";
          ExecStart = "${pkgs.writeShellScript "cleanup" ''
            find "${cfg.logging.directory}" -name "*.log" -mtime +${toString cfg.logging.retentionDays} -delete
          ''}";
        };
      };

      timers.ai-agent-log-cleanup = {
        Unit.Description = "Weekly AI agent log cleanup";
        Timer = {
          OnCalendar = "weekly";
          Persistent = true;
        };
        Install.WantedBy = [ "timers.target" ];
      };
    };
  };
}
