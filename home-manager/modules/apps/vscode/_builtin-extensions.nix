{
  pkgs,
}:
with pkgs.vscode-extensions;
[
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
  vscode-icons-team.vscode-icons # VS Code file icon theme
]
