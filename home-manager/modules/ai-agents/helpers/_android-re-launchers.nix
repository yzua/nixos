{
  config,
  constants,
  lib,
  pkgs,
}:
let
  scriptsDir = "${config.home.homeDirectory}/${constants.paths.scripts}";
  launcherScript = "${scriptsDir}/ai/android-re/opencode-android-re.sh";
  inherit (import ../../../../shared/_secret-loader.nix) loadSecretFn;
  inherit (constants.services.zai) timeout;
  inherit (constants.services.zai.models) haiku sonnet opus;

  mkAndroidReLauncher =
    {
      name,
      profile,
    }:
    pkgs.writeShellScriptBin name ''
      ANDROID_RE_OPENCODE_PROFILE=${lib.escapeShellArg profile} \
        exec ${launcherScript} "$@"
    '';

  # Android-re prompt text assembled from the markdown files at Nix eval time.
  promptLib = import ../android-re/_prompt.nix {
    inherit lib;
    homeDir = config.home.homeDirectory;
  };
  inherit (promptLib) promptText;
  escapedPrompt = lib.escapeShellArg promptText;

  # Claude Code android-re launcher.
  # modelEnv: inline bash that sets provider env vars before invoking claude.
  # extraFlags: additional claude CLI flags (e.g. --model sonnet).
  mkClaudeAndroidReLauncher =
    {
      name,
      modelEnv ? "",
      extraFlags ? "",
    }:
    pkgs.writeShellScriptBin name ''
      set -euo pipefail

      SCRIPT_DIR="${scriptsDir}/ai/android-re"
      START_LOG="''${START_LOG:-''${HOME}/Downloads/android-re-tools/re-avd-start.log}"

      # Focus the android workspace in niri
      source "''${SCRIPT_DIR}/_helpers.sh"
      NIRI_WS_REF="$(resolve_niri_android_workspace)"
      if command -v niri >/dev/null 2>&1 && niri msg version >/dev/null 2>&1; then
        if [[ -n "''${NIRI_WS_REF}" ]]; then
          niri msg action focus-workspace "''${NIRI_WS_REF}" >/dev/null 2>&1 || true
          sleep 0.3
        fi
      fi

      # Boot the emulator baseline if nothing is running
      if ! adb devices 2>/dev/null | grep -q '^emulator-'; then
        echo "No emulator running — starting Android RE baseline in background (log: ''${START_LOG})"
        nohup bash "''${SCRIPT_DIR}/re-avd.sh" start >"''${START_LOG}" 2>&1 &
        START_PID=$!
        echo "re-avd.sh start PID: ''${START_PID}"
        echo "Monitor with: tail -f ''${START_LOG}"
      else
        echo "Emulator already running — checking status..."
        bash "''${SCRIPT_DIR}/re-avd.sh" status
      fi

      # Set up model/provider env vars
      ${modelEnv}

      # Launch Ghostty with Claude Code and the android-re prompt
      if command -v ghostty >/dev/null 2>&1; then
        ghostty --title="android-re (claude)" -e claude \
          --append-system-prompt ${escapedPrompt} \
          ${extraFlags} \
          "$@"
      else
        claude \
          --append-system-prompt ${escapedPrompt} \
          ${extraFlags} \
          "$@"
      fi
    '';

  # Load Z.AI secret for GLM wrapper (mirrors claude_glm from functions.nix)
  glmModelEnv = ''
    ${loadSecretFn}
    key="$(_load_secret zai_api_key)" || return 1
    export ANTHROPIC_AUTH_TOKEN="$key"
    export ANTHROPIC_BASE_URL="${constants.services.zai.apiRoot}/anthropic"
    export API_TIMEOUT_MS="${toString timeout}"
    export ANTHROPIC_DEFAULT_HAIKU_MODEL="${haiku}"
    export ANTHROPIC_DEFAULT_SONNET_MODEL="${sonnet}"
    export ANTHROPIC_DEFAULT_OPUS_MODEL="${opus}"
  '';

in
map mkAndroidReLauncher [
  {
    name = "ocare";
    profile = "default";
  }
  {
    name = "ocglmare";
    profile = "glm";
  }
  {
    name = "ocgemare";
    profile = "gemini";
  }
  {
    name = "ocgptare";
    profile = "gpt";
  }
  {
    name = "ocorare";
    profile = "openrouter";
  }
  {
    name = "ocsare";
    profile = "sonnet";
  }
  {
    name = "oczenare";
    profile = "zen";
  }
]
++ map mkClaudeAndroidReLauncher [
  {
    name = "clare";
    extraFlags = "--dangerously-skip-permissions";
  }
  {
    name = "clglmare";
    modelEnv = glmModelEnv;
    extraFlags = "--dangerously-skip-permissions";
  }
  {
    name = "clsare";
    extraFlags = "--dangerously-skip-permissions --model sonnet";
  }
  {
    name = "clhare";
    extraFlags = "--dangerously-skip-permissions --model haiku";
  }
]
