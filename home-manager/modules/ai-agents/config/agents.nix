# Oh-My-OpenCode agent definitions and orchestration settings.
{ config, constants, ... }:

{
  programs.aiAgents = {
    opencode = {
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
            model = "openai/gpt-5.3-codex";
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
  };
}
