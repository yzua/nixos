# JavaScript/TypeScript development environment (Node, Bun, Deno, LSP, etc).

{
  config,
  lib,
  pkgs,
  ...
}:

let
  globalNpmPackages = [
    "@anthropic-ai/claude-code"
    "@google/gemini-cli"
    "@openai/codex"
    "opencode-ai"
    "btca"
    "skills"
    # MCP servers (globally installed for fast startup, avoids npx cold starts)
    "@upstash/context7-mcp"
    "@modelcontextprotocol/server-filesystem"
    "@modelcontextprotocol/server-memory"
    "@modelcontextprotocol/server-sequential-thinking"
    "@playwright/cli"
    "@magicuidesign/mcp"
    "@modelcontextprotocol/server-github"
    "agent-browser"
    "@z_ai/mcp-server"
  ];
in
{
  programs = {
    zsh.shellAliases = {
      tscl = "tsc --noEmit";
      tscw = "tsc --watch";
      tscb = "tsc --build";
      el = "eslint --fix";
      pf = "prettier --write";
      jt = "jest --watch";
      vt = "npx vitest";
      pt = "npx playwright";
      bc = "biome check";
      bf = "biome format";
      bcf = "biome check --apply";
      blint = "biome lint";
      bfmt = "biome format --write";
    };

    git.ignores = [
      "node_modules/"
      "bun.lockb"
      ".pnpm-debug.log*"
      ".yarn/install-state.gz"
      ".yarn/cache"
      ".yarn/build-state.yml"
      ".next/"
      ".nuxt/"
      ".output/"
      ".vercel/"
      ".netlify/"
      ".env"
      ".env.local"
      ".env.development.local"
      ".env.test.local"
      ".env.production.local"
      "logs"
      "npm-debug.log*"
      "yarn-debug.log*"
      "yarn-error.log*"
      "pids"
      "*.pid"
      "*.seed"
      "*.pid.lock"
      "coverage/"
      "*.lcov"
      ".nyc_output"
      "jspm_packages/"
      ".npm"
      ".eslintcache"
      ".rpt2_cache/"
      ".rts2_cache_cjs/"
      ".rts2_cache_es/"
      ".rts2_cache_umd/"
      ".node_repl_history"
      "*.tgz"
      ".yarn-integrity"
      ".parcel-cache"
      ".storybook-out"
      "tmp/"
      "temp/"
      "*.swo"
      "*~"
    ];
  };

  home = {
    # Wrapper sets system Chromium path before every playwright-cli invocation.
    # ~/.local/bin (pos 3 in PATH) takes priority over ~/.bun/bin (pos 6),
    # so this intercepts all calls regardless of env var inheritance.
    file.".local/bin/playwright-cli" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        export PLAYWRIGHT_MCP_BROWSER=chromium
        export PLAYWRIGHT_MCP_EXECUTABLE_PATH=/run/current-system/sw/bin/chromium
        exec "$HOME/.bun/bin/playwright-cli" "$@"
      '';
    };

    packages = with pkgs; [
      nodejs
      bun
      deno
      pnpm
      yarn
      typescript-language-server
      vscode-langservers-extracted
      emmet-language-server
      tailwindcss-language-server
      eslint
      prettier
      stylelint
      eslint_d
      biome
      esbuild
      swc
      live-server
      http-server
      np
      commitizen
      prisma
      graphql-language-service-cli
      netlify-cli
      supabase-cli
      dockerfile-language-server
    ];

    sessionVariables = {
      NODE_ENV = "development";
      NPM_CONFIG_PREFIX = "${config.home.homeDirectory}/.npm-global";
      PNPM_HOME = "${config.home.homeDirectory}/.local/share/pnpm";
      BUN_INSTALL = "${config.home.homeDirectory}/.bun";
      SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
      NODE_EXTRA_CA_CERTS = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
      COREPACK_ENABLE_AUTO_PIN = "1";
      COREPACK_DEFAULT_TO_LATEST = "0";
    };

    sessionPath = [
      "${config.home.homeDirectory}/.npm-global/bin"
      "${config.home.homeDirectory}/.bun/bin"
      "${config.home.homeDirectory}/.cache/.bun/bin"
      "${config.home.homeDirectory}/.local/share/pnpm"
      "${config.home.homeDirectory}/.deno/bin"
    ];

    activation.createJSWorkspace = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD mkdir -p $HOME/Projects/{javascript,typescript,react,node}
      $DRY_RUN_CMD mkdir -p $HOME/.npm-global

      $DRY_RUN_CMD ${pkgs.nodejs}/bin/npm config set prefix "$HOME/.npm-global"

      echo "📦 Managing global npm packages with bun..."
      $DRY_RUN_CMD ${pkgs.bun}/bin/bun add --global --cwd "$HOME" --no-summary ${lib.escapeShellArgs globalNpmPackages} || echo "❌ Failed to manage global npm packages"
      echo "✔ Global packages management completed"
    '';
  };
}
