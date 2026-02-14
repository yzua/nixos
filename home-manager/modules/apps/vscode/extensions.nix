# VS Code extensions (nixpkgs + marketplace).
{
  pkgs,
  ...
}:

let
  marketplace = pkgs.vscode-utils.buildVscodeMarketplaceExtension;
in
{
  programs.vscode.profiles.default.extensions =
    (with pkgs.vscode-extensions; [
      # --- Nix ---
      jnoortheen.nix-ide # Nix language support (syntax, LSP, formatting)
      mkhl.direnv # direnv integration

      # --- Python ---
      ms-python.debugpy # Python debugger
      ms-python.python # Python language support
      ms-python.vscode-pylance # Python type checker and IntelliSense
      charliermarsh.ruff # Ruff linter/formatter
      njpwerner.autodocstring # Docstring generator

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

      # --- AI Agents ---
      anthropic.claude-code # Claude Code

      # --- Productivity ---
      usernamehw.errorlens # Inline error/warning diagnostics
      gruntfuggly.todo-tree # TODO/FIXME/HACK tree view
      aaron-bond.better-comments # Colored comment annotations
      christian-kohler.path-intellisense # File path autocomplete
      ms-vscode.live-server # Local dev server with live reload
      alefragnani.bookmarks # Navigate code with bookmarks

      # --- Theming ---
      jdinhlife.gruvbox # Gruvbox color theme
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
}
