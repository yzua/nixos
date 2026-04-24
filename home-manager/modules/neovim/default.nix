# Neovim editor with LSP, completion, and modern plugins.

{ pkgs, ... }:

let
  lua = path: builtins.readFile path;
  luaModules = [
    ./lua/options.lua
    ./lua/keymaps.lua
    ./lua/diagnostics.lua
    ./lua/treesitter.lua
    ./lua/lsp.lua
    ./lua/plugins/cmp.lua
    ./lua/plugins/telescope.lua
    ./lua/plugins/neo-tree.lua
    ./lua/plugins/gitsigns.lua
    ./lua/plugins/lualine.lua
    ./lua/plugins/which-key.lua
    ./lua/plugins/indent-blankline.lua
    ./lua/plugins/comment.lua
    ./lua/plugins/autopairs.lua
    ./lua/plugins/conform.lua
    ./lua/plugins/lint.lua
    ./lua/plugins/trouble.lua
    ./lua/plugins/surround.lua
    ./lua/plugins/dap.lua
  ];
  initLuaBundle = builtins.concatStringsSep "" (map lua luaModules);
in
{
  imports = [
    ./plugins
  ];

  programs.neovim = {
    enable = true;
    # defaultEditor removed — EDITOR is set to "code" at system level (environment.nix)
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;

    # ripgrep and fd provided by home.packages (cli.nix) — available system-wide
    extraPackages = with pkgs; [
      zig # Zig compiler (required by zls)
      zls
      stylua
    ];

    withRuby = false;
    withPython3 = false;

    plugins = with pkgs.vimPlugins; [
      plenary-nvim
      nvim-web-devicons
      nui-nvim

      nvim-treesitter
      nvim-treesitter-parsers.typescript
      nvim-treesitter-parsers.tsx
      nvim-treesitter-parsers.javascript
      nvim-treesitter-parsers.rust
      nvim-treesitter-parsers.zig
      nvim-treesitter-parsers.lua
      nvim-treesitter-parsers.nix
      nvim-treesitter-parsers.json
      nvim-treesitter-parsers.yaml
      nvim-treesitter-parsers.toml
      nvim-treesitter-parsers.markdown
      nvim-treesitter-parsers.markdown_inline
      nvim-treesitter-parsers.bash
      nvim-treesitter-parsers.html
      nvim-treesitter-parsers.css
      nvim-treesitter-parsers.python
      nvim-treesitter-parsers.go
      nvim-treesitter-parsers.vim
      nvim-treesitter-parsers.vimdoc
      nvim-treesitter-parsers.regex
      nvim-treesitter-parsers.c
      nvim-treesitter-parsers.cpp
      nvim-treesitter-parsers.java
      nvim-treesitter-parsers.svelte
      nvim-treesitter-parsers.graphql
      nvim-treesitter-parsers.dockerfile

      nvim-lspconfig
      conform-nvim
      nvim-lint
      trouble-nvim

      nvim-dap
      nvim-dap-ui
      nvim-dap-virtual-text

      nvim-cmp
      cmp-nvim-lsp
      cmp-buffer
      cmp-path
      cmp_luasnip
      luasnip
      friendly-snippets

      telescope-nvim
      neo-tree-nvim

      gitsigns-nvim
      lualine-nvim
      which-key-nvim
      indent-blankline-nvim
      comment-nvim
      nvim-autopairs
      nvim-surround
      vim-sleuth
    ];

    initLua = initLuaBundle;
  };
}
