# CLI tools for file management, text processing, and development.
# NOTE: fzf and carapace are managed by programs.* modules.
# NOTE: restic managed by services.restic

{
  pkgs,
  inputs,
  ...
}:

let
  cursorAgent = pkgs.stdenvNoCC.mkDerivation rec {
    pname = "cursor-agent";
    version = "2026.04.08-a41fba1";

    src = pkgs.fetchurl {
      url = "https://downloads.cursor.com/lab/${version}/linux/x64/agent-cli-package.tar.gz";
      sha256 = "sha256-zHNiy5I61cN6BpfRv1TozdRk+2R/RNxIanCPkwqdfZE=";
    };

    nativeBuildInputs = [
      pkgs.autoPatchelfHook
      pkgs.makeWrapper
    ];

    buildInputs = [ pkgs.stdenv.cc.cc.lib ];

    sourceRoot = ".";

    installPhase = ''
      runHook preInstall

      install -d "$out/bin" "$out/libexec/cursor-agent"
      cp -r dist-package/. "$out/libexec/cursor-agent/"

      ln -s "$out/libexec/cursor-agent/cursor-agent" "$out/bin/cursor-agent"
      ln -s "$out/libexec/cursor-agent/cursor-agent" "$out/bin/agent"

      runHook postInstall
    '';

    meta = with pkgs.lib; {
      description = "Cursor terminal agent CLI";
      homepage = "https://cursor.com";
      license = licenses.unfree;
      sourceProvenance = with sourceTypes; [ binaryNativeCode ];
      platforms = [ "x86_64-linux" ];
      mainProgram = "agent";
    };
  };

  kiroCli = pkgs.stdenvNoCC.mkDerivation rec {
    pname = "kiro-cli";
    version = "1.29.6";

    src = pkgs.fetchurl {
      url = "https://prod.download.cli.kiro.dev/stable/${version}/kirocli-x86_64-linux.tar.xz";
      sha256 = "fdff585207cf5a259ac4e6563e69c12d81f03612b1be99cf7dc408ccfc48cb5f";
    };

    nativeBuildInputs = [
      pkgs.autoPatchelfHook
      pkgs.makeWrapper
    ];

    buildInputs = [ pkgs.stdenv.cc.cc.lib ];

    sourceRoot = ".";

    installPhase = ''
      runHook preInstall

      install -d "$out/bin" "$out/libexec/kiro-cli"
      cp -r kirocli/. "$out/libexec/kiro-cli/"

      install -m755 "$out/libexec/kiro-cli/bin/kiro-cli" "$out/bin/kiro-cli"
      install -m755 "$out/libexec/kiro-cli/bin/kiro-cli-chat" "$out/bin/kiro-cli-chat"
      install -m755 "$out/libexec/kiro-cli/bin/kiro-cli-term" "$out/bin/kiro-cli-term"

      makeWrapper "$out/bin/kiro-cli" "$out/bin/q" \
        --add-flags "--show-legacy-warning"
      makeWrapper "$out/bin/kiro-cli" "$out/bin/qchat" \
        --add-flags "--show-legacy-warning chat"

      runHook postInstall
    '';

    meta = with pkgs.lib; {
      description = "Kiro CLI for agentic workflows in the terminal";
      homepage = "https://kiro.dev/cli";
      license = licenses.amazonsl;
      sourceProvenance = with sourceTypes; [ binaryNativeCode ];
      platforms = [ "x86_64-linux" ];
      mainProgram = "kiro-cli";
    };
  };
in
{
  home.packages =
    with pkgs;
    [
      # Backup (restic managed by services.restic)
      borgbackup

      # Container analysis
      dive

      # Data formats
      fx

      # Documentation
      glow
      tealdeer

      # File and directory management
      duf
      dust
      fd
      fselect
      trash-cli # Safe rm replacement

      # General utilities
      actionlint
      bc
      codespell
      rsync
      typos
      watchexec

      # HTTP client
      xh

      # Log processing
      angle-grinder

      # Media processing
      imagemagick
      yt-dlp

      # Network analysis
      mitmproxy
      wireshark-cli

      # Nix tooling
      nix-diff # Derivation-level diff between NixOS generations
      nvd

      # Performance and benchmarking
      flamegraph
      hyperfine

      # Shell UI
      gum

      # System information
      fastfetch
      microfetch
      onefetch
      procs
      tokei

      # Terminal effects
      cmatrix
      peaclock

      # Terminal theming
      vivid

      # Text processing and search
      choose
      htmlq
      jq
      ripgrep
      ast-grep
      semgrep
      sd
      yq

      # Shell tools
      navi # Interactive cheatsheet browser with fzf

      # Browser
      google-chrome
      cursorAgent
      kiroCli

      # Terminal multiplexer
      tmux

      # Version control (gh managed by programs.gh in terminal/tools/gh.nix)
      git-absorb
      git-branchless # Stacked diffs, smartlog, undo for git
      git-cliff # Auto-generate changelogs from conventional commits
      git-crypt # Transparent file encryption in repos
      git-extras # 60+ git utilities (git-summary, git-effort, git-standup, etc.)
      git-interactive-rebase-tool # Better interactive rebase UI
      glab
      hcloud
      lazydocker
      serie
    ]
    ++ [
      # Git identity management (flake input)
      inputs.gitanon.packages.${pkgs.stdenv.hostPlatform.system}.default

      # Chrome DevTools MCP CLI
      (pkgs.writeShellApplication {
        name = "chrome-devtools";
        runtimeInputs = [
          pkgs.nodejs
          pkgs.google-chrome
        ];
        text = ''
          npx -y chrome-devtools-mcp@latest --executablePath ${pkgs.google-chrome}/bin/google-chrome-stable "$@"
        '';
      })
    ];
}
