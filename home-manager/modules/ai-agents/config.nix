{ config, constants, ... }:

{
  programs.aiAgents = {
    enable = true;

    globalInstructions = ''
      # NixOS Environment

      You are running on **NixOS** (flake-based, x86_64-linux). This is NOT a standard Linux distro.

      ## Key Facts

      - **No apt/dnf/pacman/brew**: Packages are managed declaratively via Nix flakes. Don't suggest `apt install` or similar.
      - **Ephemeral tools**: Use `nix-shell -p <package>` to get any tool temporarily without installing it system-wide. Examples:
        - `nix-shell -p jq` — get jq for the current shell session
        - `nix-shell -p python3Packages.requests` — get a Python package
        - `nix-shell -p nodePackages.prettier` — get a Node.js tool
        - `nix run nixpkgs#<package>` — run a package directly without entering a shell
      - **Dev environments**: Use `nix develop` (or `direnv`) for project-specific toolchains. Most projects have a `flake.nix` or `.envrc`.
      - **System config**: Lives at `~/System/` — a flake with NixOS modules + Home Manager (standalone, not a NixOS module).
      - **Apply changes**: `just home` (user-level, safe) then `just nixos` (system-level).
      - **FHS assumptions break**: `/usr/lib`, `/opt`, etc. don't exist. Use `nix-shell -p` or add packages to the flake.
      - **Compositor**: Niri (scrollable tiling Wayland), not X11. Use `wl-copy`/`wl-paste` for clipboard, not `xclip`.
      - **Multiplexer**: Zellij (not tmux). Use `zellij` for terminal multiplexing.

      ## Git Conventions

      - **Commit style**: Semantic commits — `feat:`, `fix:`, `chore:`, `refactor:`, `docs:`, `test:`, `perf:`.
      - **Scope**: Use parenthesized scope when clear — `feat(auth):`, `fix(niri):`, `chore(mcp):`.
      - **Message**: Imperative mood, lowercase after prefix. First line under 72 chars. Body explains *why*, not *what*.
      - **No force-push** to `main`/`master` unless explicitly requested.
      - **No commits** unless explicitly asked.
      - **Atomic commits**: One logical change per commit. Don't mix refactors with features.
    '';

    skills = [
      # Repo-level installs (all skills from repo)
      "obra/superpowers"
      "anthropics/skills"
      "affaan-m/everything-claude-code"
      "alirezarezvani/claude-skills"

      # Individual skills (--skill flag)
      {
        repo = "vercel-labs/skills";
        skill = "find-skills";
      }

      {
        repo = "vercel-labs/agent-skills";
        skill = "vercel-react-best-practices";
      }
      {
        repo = "vercel-labs/agent-skills";
        skill = "web-design-guidelines";
      }
      {
        repo = "remotion-dev/skills";
        skill = "remotion-best-practices";
      }
      {
        repo = "anthropics/skills";
        skill = "frontend-design";
      }
      {
        repo = "vercel-labs/agent-browser";
        skill = "agent-browser";
      }
    ];

    mcpServers = {
      context7 = {
        enable = true;
        command = "context7-mcp";
      };

      zai-mcp-server = {
        enable = true;
        command = "bunx";
        args = [ "@z_ai/mcp-server" ];
        env = {
          Z_AI_MODE = "ZAI";
        };
      };

      web-search-prime = {
        enable = false;
        type = "remote";
        url = "https://api.z.ai/api/mcp/web_search_prime/mcp";
      };

      filesystem = {
        enable = true;
        command = "mcp-server-filesystem";
        args = [ "/home/yz" ];
      };

      git = {
        enable = true;
        command = "uvx";
        args = [ "mcp-server-git" ];
      };

      memory = {
        enable = true;
        command = "mcp-server-memory";
      };

      sequential-thinking = {
        enable = true;
        command = "mcp-server-sequential-thinking";
      };

      playwright = {
        enable = true;
        command = "playwright-mcp";
        args = [
          "--executable-path"
          "/run/current-system/sw/bin/chromium"
        ];
      };

      cloudflare-docs = {
        enable = true;
        type = "remote";
        url = "https://docs.mcp.cloudflare.com/mcp";
      };

      cloudflare-workers-builds = {
        enable = false; # never connects, wastes startup time
        type = "remote";
        url = "https://builds.mcp.cloudflare.com/mcp";
      };

      cloudflare-workers-bindings = {
        enable = false; # never connects, wastes startup time
        type = "remote";
        url = "https://bindings.mcp.cloudflare.com/mcp";
      };

      cloudflare-observability = {
        enable = false; # never connects, wastes startup time
        type = "remote";
        url = "https://observability.mcp.cloudflare.com/mcp";
      };

      github = {
        enable = true;
        command = "mcp-server-github";
        env = {
          GITHUB_PERSONAL_ACCESS_TOKEN = "__GITHUB_TOKEN_PLACEHOLDER__"; # patched at activation via gh auth token
        };
      };

    };

    logging = {
      enable = true;
      directory = "${config.home.homeDirectory}/.local/share/ai-agents/logs";
      notifyOnError = true;
      retentionDays = 30;

      enableOtel = false;
    };

    claude = {
      enable = true;
      model = "opus";

      env = {
        EDITOR = "nvim";
        CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
        MAX_MCP_OUTPUT_TOKENS = "50000"; # Default 10k; raised for large codebases
        MCP_TIMEOUT = "30000"; # Default 10s; raised for npx cold starts
        ENABLE_TOOL_SEARCH = "auto:5"; # Auto-search when >5 tools match; faster with 12+ MCPs
      };

      permissions = {
        allow = [
          "Bash(git *)"
          "Bash(gh *)"
          "Bash(npm run *)"
          "Bash(npx *)"
          "Bash(pnpm *)"
          "Bash(bun *)"
          "Bash(just *)"
          "Bash(make *)"
          "Bash(cmake *)"
          "Bash(nix *)"
          "Bash(nh *)"
          "Bash(home-manager *)"
          "Bash(cargo *)"
          "Bash(rustfmt *)"
          "Bash(go *)"
          "Bash(gofmt *)"
          "Bash(zig *)"
          "Bash(python *)"
          "Bash(pip *)"
          "Bash(uv *)"
          "Bash(ruff *)"
          "Bash(biome *)"
          "Bash(prettier *)"
          "Bash(statix *)"
          "Bash(deadnix *)"
          "Bash(docker *)"
          "Bash(docker-compose *)"
          "Bash(systemctl --user *)"
          "Bash(tmux *)"
        ];
        deny = [
          "Bash(rm -rf /)"
          "Bash(rm -rf ~)"
          "Bash(rm -rf /*)"
          "Bash(> /dev/sda*)"
          "Bash(mkfs*)"
          "Bash(dd if=*)"
          "Read(.env)"
          "Read(.env.*)"
          "Read(./secrets/**)"
          "Read(.ssh/*)"
          "Read(**/id_rsa*)"
          "Read(**/id_ed25519*)"
        ];
      };

      hooks = {
        PreToolUse = [
          {
            matcher = ''tool == "Bash" && tool_input.command matches "(rm -rf|DROP|DELETE FROM|truncate)"'';
            hooks = [
              {
                type = "command";
                command = ''
                  echo "⚠️  DESTRUCTIVE COMMAND DETECTED" >&2
                  cat
                '';
              }
            ];
          }
          {
            matcher = ''tool == "Bash" && tool_input.command matches "git commit"'';
            hooks = [
              {
                type = "command";
                command = ''
                  if [ -f "justfile" ] && just --summary 2>/dev/null | grep -qw "lint"; then
                    echo "🔍 Pre-commit: running just lint..." >&2
                    just lint 2>&1 | tail -5 >&2
                  elif [ -f ".pre-commit-config.yaml" ] && command -v pre-commit >/dev/null 2>&1; then
                    echo "🔍 Pre-commit: running pre-commit..." >&2
                    pre-commit run --all-files 2>&1 | tail -5 >&2
                  elif [ -f "package.json" ] && grep -q '"lint"' package.json 2>/dev/null; then
                    echo "🔍 Pre-commit: running npm run lint..." >&2
                    npm run lint 2>&1 | tail -5 >&2
                  elif [ -f "Cargo.toml" ] && command -v cargo >/dev/null 2>&1; then
                    echo "🔍 Pre-commit: running cargo check..." >&2
                    cargo check 2>&1 | tail -5 >&2
                  fi
                  cat
                '';
              }
            ];
          }
          {
            matcher = ''tool == "Bash" && tool_input.command matches "(npm run dev|pnpm( run)? dev|yarn dev|bun run dev)"'';
            hooks = [
              {
                type = "command";
                command = ''
                  echo "[Hook] BLOCKED: Dev server must run in tmux for log access" >&2
                  echo "[Hook] Use: tmux new-session -d -s dev \"npm run dev\"" >&2
                  echo "[Hook] Then: tmux attach -t dev" >&2
                  exit 1
                '';
              }
            ];
          }
          {
            matcher = ''tool == "Bash" && tool_input.command matches "(npm (install|test)|pnpm (install|test)|yarn (install|test)?|bun (install|test)|cargo build|make|docker|pytest|vitest|playwright)"'';
            hooks = [
              {
                type = "command";
                command = ''
                  if [ -z "$TMUX" ]; then
                    echo "[Hook] Consider running in tmux for session persistence" >&2
                    echo "[Hook] tmux new -s dev  |  tmux attach -t dev" >&2
                  fi
                  cat
                '';
              }
            ];
          }
          {
            matcher = ''tool == "Bash" && tool_input.command matches "git push"'';
            hooks = [
              {
                type = "command";
                command = ''
                  echo "[Hook] Review changes before push..." >&2
                  cat
                '';
              }
            ];
          }
        ];
        Notification = [
          {
            hooks = [
              {
                type = "command";
                command = ''
                  msg=$(cat | jq -r '.message // "Needs your attention"')
                  notify-send -i dialog-information "Claude Code" "$msg" 2>/dev/null || true
                '';
              }
            ];
          }
        ];
        Stop = [
          {
            hooks = [
              {
                type = "command";
                command = ''
                  reason=$(cat | jq -r '.stop_reason // "completed"')
                  notify-send -i dialog-information "Claude Code" "Task $reason" 2>/dev/null || true
                '';
              }
            ];
          }
        ];
        PostToolUseFailure = [
          {
            hooks = [
              {
                type = "command";
                command = ''
                  INPUT=$(cat)
                  TOOL=$(echo "$INPUT" | jq -r '.tool // "unknown"')
                  ERROR=$(echo "$INPUT" | jq -r '.error // "no error"' | head -5)
                  echo "[Hook] Tool FAILED: $TOOL — $ERROR" >&2
                  echo "$INPUT"
                '';
              }
            ];
          }
        ];
        PostToolUse = [
          {
            matcher = ''tool == "Edit" && tool_input.file_path matches "\\.(ts|tsx|js|jsx|json|jsonc)$"'';
            hooks = [
              {
                type = "command";
                command = ''
                  INPUT=$(cat)
                  file_path=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')
                  if [ -n "$file_path" ] && command -v biome >/dev/null 2>&1; then
                    biome check --write "$file_path" 2>&1 | head -3 >&2
                  fi
                  echo "$INPUT"
                '';
              }
            ];
          }
          {
            matcher = ''tool == "Edit" && tool_input.file_path matches "\\.rs$"'';
            hooks = [
              {
                type = "command";
                command = ''
                  INPUT=$(cat)
                  file_path=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')
                  if [ -n "$file_path" ] && command -v rustfmt >/dev/null 2>&1; then
                    rustfmt "$file_path" 2>&1 | head -3 >&2
                  fi
                  echo "$INPUT"
                '';
              }
            ];
          }
          {
            matcher = ''tool == "Edit" && tool_input.file_path matches "\\.zig$"'';
            hooks = [
              {
                type = "command";
                command = ''
                  INPUT=$(cat)
                  file_path=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')
                  if [ -n "$file_path" ] && command -v zig >/dev/null 2>&1; then
                    zig fmt "$file_path" 2>&1 | head -3 >&2
                  fi
                  echo "$INPUT"
                '';
              }
            ];
          }
          {
            matcher = ''tool == "Edit" && tool_input.file_path matches "\\.go$"'';
            hooks = [
              {
                type = "command";
                command = ''
                  INPUT=$(cat)
                  file_path=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')
                  if [ -n "$file_path" ] && command -v gofmt >/dev/null 2>&1; then
                    gofmt -w "$file_path" 2>&1 | head -3 >&2
                  fi
                  echo "$INPUT"
                '';
              }
            ];
          }
          {
            matcher = ''tool == "Edit" && tool_input.file_path matches "\\.nix$"'';
            hooks = [
              {
                type = "command";
                command = ''
                  INPUT=$(cat)
                  file_path=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')
                  if [ -n "$file_path" ] && command -v nixfmt >/dev/null 2>&1; then
                    nixfmt "$file_path" 2>&1 | head -3 >&2
                  fi
                  echo "$INPUT"
                '';
              }
            ];
          }
          {
            matcher = ''tool == "Edit" && tool_input.file_path matches "\\.py$"'';
            hooks = [
              {
                type = "command";
                command = ''
                  INPUT=$(cat)
                  file_path=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')
                  if [ -n "$file_path" ] && command -v ruff >/dev/null 2>&1; then
                    ruff format "$file_path" 2>&1 | head -3 >&2
                  fi
                  echo "$INPUT"
                '';
              }
            ];
          }
          {
            matcher = ''tool == "Edit" && tool_input.file_path matches "\\.(yaml|yml|toml)$"'';
            hooks = [
              {
                type = "command";
                command = ''
                  INPUT=$(cat)
                  file_path=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')
                  if [ -n "$file_path" ] && command -v prettier >/dev/null 2>&1; then
                    prettier --write "$file_path" 2>&1 | head -3 >&2
                  fi
                  echo "$INPUT"
                '';
              }
            ];
          }
          {
            matcher = ''tool == "Bash" && tool_input.command matches "gh pr create"'';
            hooks = [
              {
                type = "command";
                command = ''
                  INPUT=$(cat)
                  PR_URL=$(echo "$INPUT" | jq -r '.tool_output.output // ""' | grep -oE 'https://github.com/[^/]+/[^/]+/pull/[0-9]+' || true)
                  if [ -n "$PR_URL" ]; then
                    echo "[Hook] PR created: $PR_URL" >&2
                  fi
                  echo "$INPUT"
                '';
              }
            ];
          }
          {
            matcher = ''tool == "Edit" && tool_input.file_path matches "\\.(ts|tsx|js|jsx)$"'';
            hooks = [
              {
                type = "command";
                command = ''
                  INPUT=$(cat)
                  FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')
                  if [ -n "$FILE_PATH" ] && [ -f "$FILE_PATH" ]; then
                    MATCHES=$(grep -n "console\.log" "$FILE_PATH" 2>/dev/null | head -5)
                    if [ -n "$MATCHES" ]; then
                      echo "[Hook] WARNING: console.log found in $FILE_PATH" >&2
                      echo "$MATCHES" >&2
                    fi
                  fi
                  echo "$INPUT"
                '';
              }
            ];
          }
          {
            matcher = ''tool == "Edit" && tool_input.file_path matches "\\.(ts|tsx)$"'';
            hooks = [
              {
                type = "command";
                command = ''
                  INPUT=$(cat)
                  FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')
                  if [ -n "$FILE_PATH" ] && [ -f "$FILE_PATH" ]; then
                    DIR=$(dirname "$FILE_PATH")
                    while [ "$DIR" != "/" ] && [ ! -f "$DIR/tsconfig.json" ]; do
                      DIR=$(dirname "$DIR")
                    done
                    if [ -f "$DIR/tsconfig.json" ]; then
                      TSC_OUT=$(cd "$DIR" && npx tsc --noEmit --pretty false 2>&1 | grep "$FILE_PATH" | head -10) || true
                      if [ -n "$TSC_OUT" ]; then
                        echo "[Hook] TypeScript errors:" >&2
                        echo "$TSC_OUT" >&2
                      fi
                    fi
                  fi
                  echo "$INPUT"
                '';
              }
            ];
          }
        ];
        SessionStart = [
          {
            hooks = [
              {
                type = "command";
                command = ''
                  SESSION_DIR="$HOME/.claude/session-state"
                  if [ -f "$SESSION_DIR/last-session.json" ]; then
                    echo "[Hook] Loaded previous session context" >&2
                    cat "$SESSION_DIR/last-session.json" >&2
                  fi
                  cat
                '';
              }
            ];
          }
        ];
        SessionEnd = [
          {
            hooks = [
              {
                type = "command";
                command = ''
                  SESSION_DIR="$HOME/.claude/session-state"
                  mkdir -p "$SESSION_DIR"
                  INPUT=$(cat)
                  GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
                  echo "$INPUT" | jq --arg cwd "$PWD" --arg branch "$GIT_BRANCH" '{
                    timestamp: now,
                    stop_reason: .stop_reason,
                    cwd: $cwd,
                    git_branch: $branch
                  }' > "$SESSION_DIR/last-session.json" 2>/dev/null || true
                  echo "$INPUT"
                '';
              }
            ];
          }
        ];
        PreCompact = [
          {
            hooks = [
              {
                type = "command";
                command = ''
                  SESSION_DIR="$HOME/.claude/session-state"
                  mkdir -p "$SESSION_DIR"
                  echo "[Hook] Saving state before compaction..." >&2
                  date -Iseconds > "$SESSION_DIR/last-compact.txt"
                  cat
                '';
              }
            ];
          }
        ];
      };

      extraSettings = {
        cleanupPeriodDays = 14;
        respectGitignore = true;
        alwaysThinkingEnabled = true;
        showTurnDuration = true;
        spinnerTipsEnabled = true;
        autoUpdatesChannel = "latest";
        prefersReducedMotion = false;
        attribution = {
          commit = "";
          pr = "";
        };
      };
    };

    opencode = {
      enable = true;
      model = "anthropic/claude-opus-4-6";

      plugins = [
        "oh-my-opencode"
        "opencode-antigravity-auth"
        "opencode-anthropic-auth"
      ];

      extraSettings = {
        tui = {
          theme = "gruvbox";
          show_tokens = true;
          show_cost = true;
        };
        small_model = "anthropic/claude-haiku-4-5"; # Cheap model for titles, summaries
        compaction = {
          auto = true;
          prune = true; # Remove old tool outputs during compaction
          reserved = 10000; # Reserved tokens after compaction
        };
        command = {
          test = {
            template = "Run the project test suite. If a justfile exists, use 'just check'. Otherwise find and run the appropriate test command.";
            description = "Run project tests";
          };
          deploy = {
            template = "Run the NixOS deployment pipeline: just modules && just lint && just format && just check && just home. Only run 'just nixos' if I explicitly confirm.";
            description = "Deploy NixOS configuration";
          };
          review = {
            template = "Review the staged git changes (git diff --staged). Check for: correctness, edge cases, security issues, performance problems, maintainability. Rate issues as CRITICAL/WARNING/SUGGESTION.";
            description = "Review staged changes";
          };
        };
      };

      providers = {
        google = {
          models = {
            "antigravity-gemini-3-pro" = {
              name = "Gemini 3 Pro (Antigravity)";
              limit = {
                context = 1048576;
                output = 65535;
              };
              modalities = {
                input = [
                  "text"
                  "image"
                  "pdf"
                ];
                output = [ "text" ];
              };
              variants = {
                low = {
                  thinkingLevel = "low";
                };
                high = {
                  thinkingLevel = "high";
                };
              };
            };
            "antigravity-gemini-3-flash" = {
              name = "Gemini 3 Flash (Antigravity)";
              limit = {
                context = 1048576;
                output = 65536;
              };
              modalities = {
                input = [
                  "text"
                  "image"
                  "pdf"
                ];
                output = [ "text" ];
              };
              variants = {
                minimal = {
                  thinkingLevel = "minimal";
                };
                low = {
                  thinkingLevel = "low";
                };
                medium = {
                  thinkingLevel = "medium";
                };
                high = {
                  thinkingLevel = "high";
                };
              };
            };
            "antigravity-claude-sonnet-4-5" = {
              name = "Claude Sonnet 4.5 (Antigravity)";
              limit = {
                context = 200000;
                output = 64000;
              };
              modalities = {
                input = [
                  "text"
                  "image"
                  "pdf"
                ];
                output = [ "text" ];
              };
            };
            "antigravity-claude-opus-4-6-thinking" = {
              name = "Claude Opus 4.6 Thinking (Antigravity)";
              limit = {
                context = 200000;
                output = 64000;
              };
              modalities = {
                input = [
                  "text"
                  "image"
                  "pdf"
                ];
                output = [ "text" ];
              };
              variants = {
                low = {
                  thinkingConfig = {
                    thinkingBudget = 8192;
                  };
                };
                max = {
                  thinkingConfig = {
                    thinkingBudget = 32768;
                  };
                };
              };
            };
          };
        };
      };

      ohMyOpencode = {
        enable = true;
        googleAuth = false;

        agents = {
          sisyphus = {
            model = "anthropic/claude-opus-4-6";
            description = "Primary orchestrator — delegates, verifies, ships";
            color = "#d79921"; # Gruvbox yellow
            skills = [ "git-master" ];
          };
          oracle = {
            model = "anthropic/claude-opus-4-6";
            description = "Read-only consultant for architecture and debugging";
            color = "#458588"; # Gruvbox blue
            permission = {
              edit = "deny";
              bash = "ask";
              webfetch = "allow";
            };
          };
          librarian = {
            model = "anthropic/claude-sonnet-4-5";
            description = "External reference search — docs, OSS, GitHub examples";
            color = "#b16286"; # Gruvbox purple
            permission = {
              edit = "deny";
              bash = "deny";
              webfetch = "allow";
            };
          };
          explore = {
            model = "anthropic/claude-haiku-4-5";
            description = "Fast contextual grep — codebase patterns and structure";
            color = "#98971a"; # Gruvbox green
            permission = {
              edit = "deny";
              bash = "deny";
              webfetch = "deny";
            };
          };
          multimodal-looker = {
            model = "google/gemini-3-flash";
            description = "Visual content analysis — PDFs, images, diagrams";
            color = "#689d6a"; # Gruvbox aqua
            skills = [ "playwright" ];
          };
          prometheus = {
            model = "anthropic/claude-opus-4-6";
            variant = "max";
            description = "Strategic planner with interview mode";
            color = "#cc241d"; # Gruvbox red
          };
          metis = {
            model = "anthropic/claude-opus-4-6";
            description = "Pre-planning analysis — hidden requirements, ambiguities";
            color = "#d65d0e"; # Gruvbox orange
          };
          momus = {
            model = "anthropic/claude-opus-4-6";
            description = "Plan reviewer — validates clarity and completeness";
            color = "#928374"; # Gruvbox gray
          };
          atlas = {
            model = "anthropic/claude-sonnet-4-5";
            description = "Orchestrator/conductor — coordinates task execution";
            color = "#fabd2f"; # Gruvbox bright yellow
            skills = [ "git-master" ];
          };
          hephaestus = {
            model = "anthropic/claude-opus-4-6";
            description = "Autonomous deep worker — goal-oriented, long-running tasks";
            color = "#fb4934"; # Gruvbox bright red
          };
        };

        extraSettings = {
          # === Background Task Concurrency ===
          background_task = {
            defaultConcurrency = 5;
            staleTimeoutMs = 180000; # Kill stale tasks after 3 minutes
            providerConcurrency = {
              anthropic = 3;
              openai = 5;
              google = 10;
            };
            modelConcurrency = {
              "anthropic/claude-opus-4-6" = 2; # Expensive — limit hard
              "anthropic/claude-haiku-4-5" = 8; # Cheap — allow many
              "google/gemini-3-flash" = 10; # Cheap — allow many
            };
          };

          # === Category Model Assignments ===
          categories = {
            "visual-engineering" = {
              model = "google/antigravity-gemini-3-pro";
            };
            ultrabrain = {
              model = "anthropic/claude-opus-4-6";
            };
            deep = {
              model = "anthropic/claude-opus-4-6";
              variant = "max";
            };
            artistry = {
              model = "google/antigravity-gemini-3-pro";
            };
            quick = {
              model = "anthropic/claude-haiku-4-5";
            };
            "unspecified-low" = {
              model = "anthropic/claude-sonnet-4-5";
            };
            "unspecified-high" = {
              model = "anthropic/claude-opus-4-6";
              variant = "max";
            };
            writing = {
              model = "google/antigravity-gemini-3-flash";
            };
          };

          # === Tmux Visual Multi-Agent ===
          tmux = {
            enabled = true;
            layout = "main-vertical";
            main_pane_size = 60;
            main_pane_min_width = 120;
            agent_pane_min_width = 40;
          };

          # === Git Master ===
          git_master = {
            commit_footer = false;
            include_co_authored_by = false;
          };

          # === Experimental Features ===
          experimental = {
            aggressive_truncation = true; # Saves tokens on large outputs
            preemptive_compaction = true; # Compact before hitting limits
          };

          # === Disabled Hooks ===
          disabled_hooks = [
            "agent-usage-reminder" # Noisy reminder (already know to use agents)
            "startup-toast" # Startup noise
          ];
        };
      };
    };

    codex = {
      enable = true;
      useWrapper = true;
      model = "gpt-5.3-codex";
      personality = "pragmatic";
      reasoningEffort = "medium";
      approvalPolicy = "on-request";
      trustedProjects = [
        "/home/yz/System"
      ];
      extraToml = ''
        [features]
        request_rule = true
        collaboration_modes = true
        personality = true
        model_reasoning_summary = true

        [profiles.nix]
        model_reasoning_effort = "high"
        approval_policy = "on-request"
        developer_instructions = """
        You are working on a NixOS flake-based configuration.
        Use 'just modules' to validate imports, 'just lint' for linting,
        'just format' for formatting, 'just check' for flake evaluation.
        Follow patterns in nearby modules. Use lib.mkIf for conditionals.
        Custom options live under mySystem.* namespace.
        """

        [profiles.review]
        personality = "pragmatic"
        model_reasoning_effort = "high"
        approval_policy = "on-request"
      '';
    };

    gemini = {
      enable = true;
      theme = "Gruvbox";
      sandboxMode = "cautious";

      extraSettings = {
        codeExecution = true;
        searchGrounding = true;
        context = {
          fileName = [
            "GEMINI.md"
            "AGENTS.md"
          ];
          importFormat = "markdown";
          fileFiltering = {
            respectGitIgnore = true;
            respectGeminiIgnore = true;
            enableRecursiveFileSearch = true;
          };
        };
        general = {
          vimMode = true;
          enableAutoUpdate = true;
          enableAutoUpdateNotification = true;
          checkpointing.enabled = true;
          sessionRetention = {
            enabled = true;
            maxAge = "30d";
          };
        };
        privacy = {
          usageStatisticsEnabled = false;
        };
        ui = {
          hideTips = true;
          hideBanner = true;
          showLineNumbers = true;
          customThemes = {
            Gruvbox = {
              name = "Gruvbox";
              type = "custom";
              Background = constants.color.bg_soft;
              Foreground = constants.color.fg0;
              LightBlue = constants.color.blue;
              AccentBlue = constants.color.blue_dim;
              AccentPurple = constants.color.purple_dim;
              AccentCyan = constants.color.aqua;
              AccentGreen = constants.color.green;
              AccentYellow = constants.color.yellow;
              AccentRed = constants.color.red;
              Comment = constants.color.gray;
              Gray = constants.color.gray_dim;
              DiffAdded = constants.color.green;
              DiffRemoved = constants.color.red;
            };
          };
          theme = "Gruvbox";
        };
        experimental = {
          enableAgents = true;
        };
        modelConfigs = {
          customAliases = {
            fast = {
              modelConfig = {
                model = "gemini-2.5-flash-lite";
                generateContentConfig = {
                  temperature = 0;
                  maxOutputTokens = 8192;
                };
              };
            };
            deep = {
              modelConfig = {
                model = "gemini-3-pro-preview";
                generateContentConfig = {
                  thinkingConfig = {
                    thinkingLevel = "HIGH";
                  };
                };
              };
            };
            code = {
              modelConfig = {
                model = "gemini-2.5-pro";
                generateContentConfig = {
                  thinkingConfig = {
                    thinkingLevel = "HIGH";
                  };
                  maxOutputTokens = 65536;
                };
              };
            };
          };
        };
        tools = {
          approvalMode = "auto_edit";
        };
        model = {
          compressionThreshold = 0.75; # Wait until 75% full before compressing (was 0.5)
        };
        hooks = {
          AfterTool = [
            {
              matcher = "write_file|replace";
              hooks = [
                {
                  name = "auto-format";
                  type = "command";
                  command = builtins.concatStringsSep " " [
                    "INPUT=$(cat);"
                    "FILE_PATH=$(echo \"$INPUT\" | jq -r '.arguments.path // \"\"');"
                    "if [ -n \"$FILE_PATH\" ]; then"
                    "case \"$FILE_PATH\" in"
                    "*.nix) command -v nixfmt >/dev/null 2>&1 && nixfmt \"$FILE_PATH\" 2>/dev/null ;;"
                    "*.ts|*.tsx|*.js|*.jsx|*.json) command -v biome >/dev/null 2>&1 && biome check --write \"$FILE_PATH\" 2>/dev/null ;;"
                    "*.rs) command -v rustfmt >/dev/null 2>&1 && rustfmt \"$FILE_PATH\" 2>/dev/null ;;"
                    "*.go) command -v gofmt >/dev/null 2>&1 && gofmt -w \"$FILE_PATH\" 2>/dev/null ;;"
                    "*.py) command -v ruff >/dev/null 2>&1 && ruff format \"$FILE_PATH\" 2>/dev/null ;;"
                    "*.zig) command -v zig >/dev/null 2>&1 && zig fmt \"$FILE_PATH\" 2>/dev/null ;;"
                    "esac;"
                    "fi;"
                    "echo \"$INPUT\""
                  ];
                  timeout = 10000;
                }
              ];
            }
          ];
        };
      };
    };
  };
}
