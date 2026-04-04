# Oh-My-OpenCode agent definitions and orchestration settings.

{ constants, ... }:

let
  opusModel = "anthropic/claude-opus-4-6";
  sonnetModel = "anthropic/claude-sonnet-4-6";
  haikuModel = "anthropic/claude-haiku-4-5";
  gptModel = "openai/gpt-5.4";
  geminiProModel = "google/gemini-2.5-pro";
  geminiFlashModel = "google/gemini-2.5-flash";
  mkCategory =
    model: variant:
    {
      inherit model;
    }
    // (if variant == null then { } else { inherit variant; });
in

{
  programs.aiAgents = {
    opencode = {
      ohMyOpencode = {
        agents = {
          sisyphus = {
            model = opusModel;
            description = "Primary orchestrator — delegates, verifies, ships";
            color = constants.color.yellow_dim;
            skills = [ "git-master" ];
          };
          oracle = {
            model = opusModel;
            description = "Read-only consultant for architecture and debugging";
            color = constants.color.blue_dim;
            permission = {
              edit = "deny";
              bash = "ask";
              webfetch = "allow";
            };
          };
          librarian = {
            model = sonnetModel;
            description = "External reference search — docs, OSS, GitHub examples";
            color = constants.color.purple_dim;
            permission = {
              edit = "deny";
              bash = "deny";
              webfetch = "allow";
            };
          };
          explore = {
            model = haikuModel;
            description = "Fast contextual grep — codebase patterns and structure";
            color = constants.color.green_dim;
            permission = {
              edit = "deny";
              bash = "deny";
              webfetch = "deny";
            };
          };
          multimodal-looker = {
            model = sonnetModel;
            description = "Visual content analysis — PDFs, images, diagrams";
            color = constants.color.aqua_dim;
          };
          prometheus = {
            model = opusModel;
            variant = "max";
            description = "Strategic planner with interview mode";
            color = constants.color.red_dim;
          };
          metis = {
            model = opusModel;
            description = "Pre-planning analysis — hidden requirements, ambiguities";
            color = constants.color.orange_dim;
          };
          momus = {
            model = opusModel;
            description = "Plan reviewer — validates clarity and completeness";
            color = constants.color.gray;
          };
          atlas = {
            model = sonnetModel;
            description = "Orchestrator/conductor — coordinates task execution";
            color = constants.color.yellow;
            skills = [ "git-master" ];
          };
          hephaestus = {
            model = gptModel;
            description = "Autonomous deep worker — goal-oriented, long-running tasks";
            color = constants.color.red;
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
              ${opusModel} = 2; # Expensive — limit hard
              ${haikuModel} = 8; # Cheap — allow many
              ${geminiFlashModel} = 10; # Cheap — allow many
            };
          };

          # === Category Model Assignments ===
          categories = {
            "visual-engineering" = mkCategory geminiProModel null;
            ultrabrain = mkCategory opusModel null;
            deep = mkCategory opusModel "max";
            artistry = mkCategory geminiProModel null;
            quick = mkCategory haikuModel null;
            "unspecified-low" = mkCategory sonnetModel null;
            "unspecified-high" = mkCategory opusModel "max";
            writing = mkCategory geminiFlashModel null;
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
