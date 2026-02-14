# VS Code editor with declarative extensions and writable settings.
{
  config,
  lib,
  pkgs,
  constants,
  ...
}:

let
  marketplace = pkgs.vscode-utils.buildVscodeMarketplaceExtension;

  settingsJson = builtins.toJSON {
    "workbench.colorTheme" = "Gruvbox Dark Soft";
    "workbench.iconTheme" = "vscode-icons";
    "workbench.activityBar.location" = "top";
    "workbench.sideBar.location" = "right";
    "workbench.layoutControl.enabled" = false;
    "workbench.navigationControl.enabled" = false;
    "workbench.startupEditor" = "none";
    "window.commandCenter" = false;
    "window.menuBarVisibility" = "toggle";
    "window.titleBarStyle" = "custom";
    "chat.commandCenter.enabled" = false;
    "editor.fontFamily" = "'${constants.font.mono}', 'Noto Color Emoji', monospace";
    "editor.fontSize" = constants.font.size;
    "editor.fontLigatures" = true;
    "editor.minimap.enabled" = false;
    "editor.renderWhitespace" = "boundary";
    "editor.bracketPairColorization.enabled" = true;
    "editor.guides.bracketPairs" = "active";
    "editor.smoothScrolling" = true;
    "editor.cursorSmoothCaretAnimation" = "on";
    "editor.cursorBlinking" = "smooth";
    "editor.linkedEditing" = true;
    "editor.stickyScroll.enabled" = true;
    "editor.inlineSuggest.enabled" = true;
    "editor.wordWrap" = "off";
    "editor.tabSize" = 2;
    "editor.insertSpaces" = true;
    "editor.detectIndentation" = true;
    "editor.formatOnSave" = true;
    "editor.formatOnPaste" = false;
    "editor.codeActionsOnSave" = {
      "source.fixAll" = "explicit";
      "source.organizeImports" = "explicit";
    };
    "files.trimTrailingWhitespace" = true;
    "files.insertFinalNewline" = true;
    "files.trimFinalNewlines" = true;
    "files.autoSave" = "afterDelay";
    "files.autoSaveDelay" = 1000;
    "files.exclude" = {
      "**/.git" = true;
      "**/.DS_Store" = true;
      "**/node_modules" = true;
      "**/__pycache__" = true;
      "**/.pytest_cache" = true;
      "**/result" = true;
      "**/.zig-cache" = true;
      "**/target" = true;
    };
    "files.watcherExclude" = {
      "**/node_modules/**" = true;
      "**/.git/objects/**" = true;
      "**/result/**" = true;
      "**/target/**" = true;
      "**/.zig-cache/**" = true;
    };
    "terminal.integrated.fontFamily" = "'${constants.font.mono}'";
    "terminal.integrated.fontSize" = constants.font.size;
    "terminal.integrated.defaultProfile.linux" = "zsh";
    "terminal.integrated.smoothScrolling" = true;
    "terminal.integrated.gpuAcceleration" = "on";
    "explorer.confirmDelete" = false;
    "explorer.confirmDragAndDrop" = false;
    "explorer.sortOrder" = "type";
    "explorer.compactFolders" = false;
    "search.exclude" = {
      "**/node_modules" = true;
      "**/result" = true;
      "**/.direnv" = true;
      "**/target" = true;
      "**/.zig-cache" = true;
    };
    "git.autofetch" = true;
    "git.confirmSync" = false;
    "git.enableSmartCommit" = true;
    "nix.enableLanguageServer" = true;
    "nix.serverPath" = "nil";
    "nix.serverSettings" = {
      nil = {
        formatting.command = [ "nixfmt" ];
        nix.flake.autoArchive = true;
      };
    };
    "python.analysis.typeCheckingMode" = "basic";
    "python.analysis.autoImportCompletions" = true;
    "[python]" = {
      "editor.defaultFormatter" = "charliermarsh.ruff";
      "editor.formatOnSave" = true;
      "editor.codeActionsOnSave" = {
        "source.fixAll.ruff" = "explicit";
        "source.organizeImports.ruff" = "explicit";
      };
    };
    "go.lintTool" = "golangci-lint";
    "go.lintOnSave" = "workspace";
    "go.formatTool" = "goimports";
    "go.useLanguageServer" = true;
    "[go]" = {
      "editor.defaultFormatter" = "golang.go";
      "editor.formatOnSave" = true;
      "editor.codeActionsOnSave"."source.organizeImports" = "explicit";
    };
    "deno.enable" = false;
    "zig.path" = "zig";
    "zig.zls.path" = "zls";
    "[zig]" = {
      "editor.defaultFormatter" = "ziglang.vscode-zig";
      "editor.formatOnSave" = true;
      "editor.tabSize" = 4;
    };
    "rust-analyzer.check.command" = "clippy";
    "rust-analyzer.inlayHints.chainingHints.enable" = true;
    "rust-analyzer.inlayHints.typeHints.enable" = true;
    "[rust]" = {
      "editor.defaultFormatter" = "rust-lang.rust-analyzer";
      "editor.formatOnSave" = true;
      "editor.tabSize" = 4;
    };
    "[typescript]"."editor.defaultFormatter" = "biomejs.biome";
    "[typescriptreact]"."editor.defaultFormatter" = "biomejs.biome";
    "[javascript]"."editor.defaultFormatter" = "biomejs.biome";
    "[javascriptreact]"."editor.defaultFormatter" = "biomejs.biome";
    "[json]"."editor.defaultFormatter" = "biomejs.biome";
    "[jsonc]"."editor.defaultFormatter" = "biomejs.biome";
    "[svelte]"."editor.defaultFormatter" = "svelte.svelte-vscode";
    "[html]" = {
      "editor.defaultFormatter" = "vscode.html-language-features";
      "editor.tabSize" = 2;
    };
    "[css]"."editor.defaultFormatter" = "vscode.css-language-features";
    "[scss]"."editor.defaultFormatter" = "vscode.css-language-features";
    "css.lint.unknownAtRules" = "ignore";
    "[markdown]" = {
      "editor.defaultFormatter" = "yzhang.markdown-all-in-one";
      "editor.wordWrap" = "on";
      "files.trimTrailingWhitespace" = false;
    };
    "shellcheck.executablePath" = "shellcheck";
    "[shellscript]"."editor.tabSize" = 2;
    "[yaml]" = {
      "editor.tabSize" = 2;
      "editor.autoIndent" = "advanced";
    };
    "yaml.schemas" = {
      "https://json.schemastore.org/github-workflow.json" = ".github/workflows/*.{yml,yaml}";
      "https://json.schemastore.org/github-action.json" = ".github/actions/*/action.{yml,yaml}";
      "https://json.schemastore.org/docker-compose.json" = "docker-compose*.{yml,yaml}";
    };
    "[toml]"."editor.defaultFormatter" = "tamasfe.even-better-toml";
    "[dockerfile]"."editor.tabSize" = 4;
    "tailwindCSS.emmetCompletions" = true;
    "tailwindCSS.classAttributes" = [
      "class"
      "className"
      "ngClass"
      "class:list"
    ];
    "headwind.runOnSave" = true;
    "errorLens.gutterIconsEnabled" = true;
    "errorLens.messageMaxChars" = 120;
    "todo-tree.general.tags" = [
      "BUG"
      "HACK"
      "FIXME"
      "TODO"
      "XXX"
      "NOTE"
      "PERF"
      "SAFETY"
    ];
    "liveServer.settings.donotShowInfoMsg" = true;
    "liveServer.settings.donotVerifyTags" = true;
    "emmet.includeLanguages" = {
      "javascript" = "javascriptreact";
      "typescript" = "typescriptreact";
      "svelte" = "html";
    };
    "emmet.triggerExpansionOnTab" = true;
    "update.mode" = "none";
    "extensions.autoCheckUpdates" = false;
    "extensions.autoUpdate" = false;
    "update.showReleaseNotes" = false;
    "settingsSync.enable" = false;
    "window.autoDetectColorScheme" = false;
    "telemetry.telemetryLevel" = "off";
    "redhat.telemetry.enabled" = false;
    "security.workspace.trust.enabled" = false;
    "cSpell.enableFiletypes" = [
      "nix"
      "shellscript"
      "dockerfile"
    ];
  };
in
{
  programs.vscode = {
    enable = true;
    package = pkgs.vscode-fhs; # Unstable channel — latest VS Code for extension compat

    # Fully declarative — only listed extensions are installed
    mutableExtensionsDir = true;

    profiles.default = {
      # NOTE: enableUpdateCheck and enableExtensionUpdateCheck are NOT set here
      # because they cause HM to generate a read-only settings.json symlink,
      # conflicting with the writable copy from the activation script below.
      # Equivalent settings are in settingsJson: "update.mode" = "none",
      # "extensions.autoCheckUpdates" = false, "extensions.autoUpdate" = false.

      # === Extensions ===
      extensions =
        (with pkgs.vscode-extensions; [
          # --- Nix ---
          arrterian.nix-env-selector # Nix environment selector
          jnoortheen.nix-ide # Nix language support (syntax, LSP, formatting)
          mkhl.direnv # direnv integration

          # --- Python ---
          ms-python.debugpy # Python debugger
          ms-python.python # Python language support
          ms-python.vscode-pylance # Python type checker and IntelliSense
          charliermarsh.ruff # Ruff linter/formatter
          njpwerner.autodocstring # Docstring generator
          ms-toolsai.jupyter # Jupyter notebook support

          # --- Go ---
          golang.go # Go language support (IntelliSense, debugging, linting)

          # --- Zig ---
          ziglang.vscode-zig # Zig language support

          # --- Rust ---
          rust-lang.rust-analyzer # Rust language server
          vadimcn.vscode-lldb # LLDB debugger (Rust/C/C++)
          fill-labs.dependi # Dependency version management (Cargo, npm, etc.)

          # --- TypeScript / JavaScript ---
          yoavbls.pretty-ts-errors # Human-readable TypeScript errors
          wix.vscode-import-cost # Display import sizes inline
          formulahendry.auto-rename-tag # Auto rename paired HTML/XML tags
          formulahendry.auto-close-tag # Auto close HTML/XML tags
          christian-kohler.npm-intellisense # npm module import autocomplete

          # --- HTML / CSS ---
          ecmel.vscode-html-css # HTML CSS class completion
          naumovs.color-highlight # Highlight CSS colors inline
          vincaslt.highlight-matching-tag # Highlight matching HTML tags

          # --- Tailwind CSS ---
          bradlc.vscode-tailwindcss # Tailwind CSS IntelliSense

          # --- Svelte ---
          svelte.svelte-vscode # Svelte language support

          # --- Deno / Bun ---
          denoland.vscode-deno # Deno language support

          # --- Linting / Formatting ---
          biomejs.biome # Biome formatter/linter (JS/TS)
          editorconfig.editorconfig # EditorConfig support
          timonwong.shellcheck # ShellCheck integration
          foxundermoon.shell-format # Shell script formatter (shfmt)
          davidanson.vscode-markdownlint # Markdown linting
          oderwat.indent-rainbow # Colorize indentation levels

          # --- DevOps / Infrastructure ---
          ms-azuretools.vscode-docker # Docker support
          ms-kubernetes-tools.vscode-kubernetes-tools # Kubernetes support

          # --- Remote Development ---
          ms-vscode-remote.remote-ssh # Remote SSH
          ms-vscode-remote.remote-containers # Dev Containers

          # --- Data / Config Formats ---
          mikestead.dotenv # .env file syntax highlighting
          redhat.vscode-yaml # YAML language support
          tamasfe.even-better-toml # TOML language support
          mechatroner.rainbow-csv # CSV column coloring
          yzhang.markdown-all-in-one # Markdown editing (TOC, preview, shortcuts)

          # --- Git ---
          eamodio.gitlens # Git blame, history, comparison
          github.vscode-pull-request-github # GitHub PR review in editor

          # --- AI Agents ---
          anthropic.claude-code # Claude Code

          # --- Productivity ---
          usernamehw.errorlens # Inline error/warning diagnostics
          gruntfuggly.todo-tree # TODO/FIXME/HACK tree view
          aaron-bond.better-comments # Colored comment annotations
          christian-kohler.path-intellisense # File path autocomplete
          ms-vscode.live-server # Local dev server with live reload
          alefragnani.bookmarks # Navigate code with bookmarks
          streetsidesoftware.code-spell-checker # Catch typos in code and comments

          # --- Theming ---
          jdinhlife.gruvbox # Gruvbox color theme
          vscode-icons-team.vscode-icons # File icons
        ])
        ++ [
          # --- Marketplace extensions (not in nixpkgs) ---

          # Python
          (marketplace {
            mktplcRef = {
              publisher = "kevinrose";
              name = "vsc-python-indent";
              version = "1.21.0";
              sha256 = "sha256-SvJhVG8sofzV0PebZG4IIORX3AcfmErDQ00tRF9fk/4=";
            };
          })

          # TypeScript / JavaScript
          (marketplace {
            mktplcRef = {
              publisher = "ms-vscode";
              name = "vscode-typescript-next";
              version = "6.0.20260213";
              sha256 = "sha256-o3U1U+cTGIzBDf9ESCExVs9LKgdp9L2fXI7jbFn6Zt8=";
            };
          })
          (marketplace {
            mktplcRef = {
              publisher = "pmneo";
              name = "tsimporter";
              version = "2.0.1";
              sha256 = "sha256-JQ7dAliryvVXH0Rg1uheSznOHqbp/BMwwlePH9P0kog=";
            };
          })
          (marketplace {
            mktplcRef = {
              publisher = "dsznajder";
              name = "es7-react-js-snippets";
              version = "4.4.3";
              sha256 = "sha256-QF950JhvVIathAygva3wwUOzBLjBm7HE3Sgcp7f20Pc=";
            };
          })

          # HTML / CSS
          (marketplace {
            mktplcRef = {
              publisher = "pranaygp";
              name = "vscode-css-peek";
              version = "4.4.3";
              sha256 = "sha256-oY+mpDv2OTy5hFEk2DMNHi9epFm4Ay4qi0drCXPuYhU=";
            };
          })
          (marketplace {
            mktplcRef = {
              publisher = "Zignd";
              name = "html-css-class-completion";
              version = "1.20.0";
              sha256 = "sha256-3BEppTBc+gjZW5XrYLPpYUcx3OeHQDPW8z7zseJrgsE=";
            };
          })

          # Tailwind CSS
          (marketplace {
            mktplcRef = {
              publisher = "heybourn";
              name = "headwind";
              version = "1.7.0";
              sha256 = "sha256-yXsZoSuJQTdbHLjEERXX2zVheqNYmcPXs97/uQYa7og=";
            };
          })
          (marketplace {
            mktplcRef = {
              publisher = "stivo";
              name = "tailwind-fold";
              version = "0.2.0";
              sha256 = "sha256-yH3eA5jgBwxqnpFQkg91KQMkQps5iM1v783KQkQcWUU=";
            };
          })

          # Svelte
          (marketplace {
            mktplcRef = {
              publisher = "ardenivanov";
              name = "svelte-intellisense";
              version = "0.7.1";
              sha256 = "sha256-/AiGMgwCeD9B3y8LxTe6HoIswLuCnLbmwV7fxwfWSLw=";
            };
          })

          # Vite / Testing
          (marketplace {
            mktplcRef = {
              publisher = "vitest";
              name = "explorer";
              version = "1.44.0";
              sha256 = "sha256-z8JQEWSSLw+EDEfJWrHYy7vT2kAdsFybFcVkl5w5WfM=";
            };
          })

          # Node.js
          (marketplace {
            mktplcRef = {
              publisher = "naumovs";
              name = "node-modules-resolve";
              version = "1.0.2";
              sha256 = "sha256-RuNl959WtpSZbSOlYJCsiMkXMRIlFxDfrFRLypW0SkY=";
            };
          })
          (marketplace {
            mktplcRef = {
              publisher = "jasonnutter";
              name = "search-node-modules";
              version = "1.3.0";
              sha256 = "sha256-X2CkCVF46McnXDlASlRHKixlAzR+hU4ys8A8JsbpfYI=";
            };
          })

          # Bun
          (marketplace {
            mktplcRef = {
              publisher = "oven";
              name = "bun-vscode";
              version = "0.0.32";
              sha256 = "sha256-VlruOHiF5/wVhVVW1rq6DEc90u3IwbxD/tpTXyphD+U=";
            };
          })

          # Package Management
          (marketplace {
            mktplcRef = {
              publisher = "pflannery";
              name = "vscode-versionlens";
              version = "1.22.4";
              sha256 = "sha256-yEhFRRwaqq4OH1oEjD2E+8y7DCVbvvvwa3r6ujq7IGg=";
            };
          })

          # Security / Linting
          (marketplace {
            mktplcRef = {
              publisher = "exiasr";
              name = "hadolint";
              version = "1.1.2";
              sha256 = "sha256-6GO1f8SP4CE8yYl87/tm60FdGHqHsJA4c2B6UKVdpgM=";
            };
          })

          # API Client
          (marketplace {
            mktplcRef = {
              publisher = "rangav";
              name = "vscode-thunder-client";
              version = "2.39.4";
              sha256 = "sha256-c8UxN9LAS37EYY/oHi2kLD5XO//Jdd7VpAMscG9XT3E=";
            };
          })

          # Git
          (marketplace {
            mktplcRef = {
              publisher = "mhutchie";
              name = "git-graph";
              version = "1.30.0";
              sha256 = "sha256-sHeaMMr5hmQ0kAFZxxMiRk6f0mfjkg2XMnA4Gf+DHwA=";
            };
          })

          # Go
          (marketplace {
            mktplcRef = {
              publisher = "premparihar";
              name = "gotestexplorer";
              version = "0.1.13";
              sha256 = "sha256-CIqZ1yE9bAHuKvVcdD+Ph8kPgo/a9N+zqELYWxVV8F8=";
            };
          })

          # AI Agents
          (marketplace {
            mktplcRef = {
              publisher = "sst-dev";
              name = "opencode";
              version = "0.0.13";
              sha256 = "sha256-6adXUaoh/OP5yYItH3GAQ7GpupfmTGaxkKP6hYUMYNQ=";
            };
          })
          (marketplace {
            mktplcRef = {
              publisher = "openai";
              name = "chatgpt";
              version = "0.5.75";
              sha256 = "sha256-kK511BbcxWBCE3lJ5cAoiv3afeHHy4vff+rVNLmWYr0=";
            };
          })
        ];

    };
  };

  # Settings managed via activation script (writable file, not nix store symlink).
  # Extensions can modify settings at runtime; `just home` resets to baseline.
  home.activation.vscodeWritableSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    SETTINGS_DIR="$HOME/.config/Code/User"
    SETTINGS_FILE="$SETTINGS_DIR/settings.json"

    mkdir -p "$SETTINGS_DIR"

    if [ -L "$SETTINGS_FILE" ]; then
      rm "$SETTINGS_FILE"
    fi

    cp ${pkgs.writeText "vscode-settings.json" settingsJson} "$SETTINGS_FILE"
    chmod 644 "$SETTINGS_FILE"
  '';
}
