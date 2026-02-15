# VS Code baseline settings (written as mutable settings.json at activation).
{
  constants,
  pkgs,
}:

{
  "workbench.colorTheme" = "Gruvbox Dark Soft";
  "workbench.iconTheme" = "vs-seti";
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
  "git.enableCommitSigning" = true;
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
  "shellcheck.executablePath" = "${pkgs.shellcheck}/bin/shellcheck";
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
  "security.workspace.trust.enabled" = true;
  "window.zoomLevel" = 0.5;
}
