# Zsh core options, history, Oh My Zsh, plugins, keymap, and setOptions.

{
  config,
  lib,
  pkgs,
  ...
}:

{
  programs.zsh = {
    enable = true;
    enableCompletion = false; # Carapace handles completions
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    # Privacy-conscious history
    history = {
      size = 10000;
      save = 10000;
      path = "${config.xdg.dataHome}/zsh/history";
      ignoreDups = true;
      ignoreSpace = true;
      ignorePatterns = [
        "rm *"
        "kill *"
        "pkill *"
        "*token*"
        "*TOKEN*"
        "*password*"
        "*PASSWORD*"
        "*secret*"
        "*SECRET*"
        "*API_KEY*"
        "*api_key*"
        "*ANTHROPIC*"
        "export *KEY*"
        "export *TOKEN*"
        "export *SECRET*"
        "export *PASSWORD*"
        "curl *-H*Auth*"
        "wget *--password*"
        "*bearer*"
        "*BEARER*"
        "*jwt*"
        "*JWT*"
        "ssh *@*"
        "scp *@*"
        "*sops*"
        "*SOPS*"
        "*decrypt*"
        "*DECRYPT*"
      ];
      expireDuplicatesFirst = true; # Remove duplicates first when trimming
      extended = true; # Save timestamps and durations
    };

    oh-my-zsh = {
      enable = true;
      theme = ""; # Starship handles the prompt

      plugins = [
        "sudo" # Double-ESC to prepend sudo
        "extract" # Universal archive extraction
        "copypath" # Copy current path to clipboard
        "copyfile" # Copy file contents to clipboard
        "bgnotify" # Notify on long-running commands
      ];
    };

    initContent = lib.mkAfter ''
      # Silence bgnotify D-Bus errors when notification daemon is unavailable
      __bgnotify_notifier() { notify-send "$1" "$2" 2>/dev/null || true; }
    '';

    plugins = [
      {
        name = "fzf-tab";
        src = "${pkgs.zsh-fzf-tab}/share/fzf-tab";
      }
    ];

    defaultKeymap = "viins"; # Vi insert mode (hybrid vi/emacs)
    setOptions = [
      "GLOB_DOTS"
      "EXTENDED_GLOB"
      "AUTO_CD"
      "AUTO_PUSHD"
      "PUSHD_IGNORE_DUPS"
      "PUSHD_SILENT"
      "COMPLETE_IN_WORD"
      "ALWAYS_TO_END"
      "NO_BEEP"
      "CORRECT"
      "INTERACTIVE_COMMENTS"
      "MAGIC_EQUAL_SUBST"
      "NONOMATCH"
      "NOTIFY"
      "NUMERIC_GLOB_SORT"
      "PROMPT_SUBST"
      "HIST_BEEP"
      "HIST_FIND_NO_DUPS"
      "HIST_IGNORE_ALL_DUPS"
      "HIST_SAVE_NO_DUPS"
      "HIST_VERIFY"
      "INC_APPEND_HISTORY"
      "SHARE_HISTORY"
    ];
  };
}
