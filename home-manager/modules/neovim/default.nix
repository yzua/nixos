# Neovim editor with LSP, completion, and modern plugins.
{ pkgs, ... }:

let
  lua = path: builtins.readFile path;
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

    plugins = with pkgs.vimPlugins; [
      plenary-nvim
      nvim-web-devicons
      nui-nvim

      (nvim-treesitter.withPlugins (p: [
        p.typescript
        p.tsx
        p.javascript
        p.rust
        p.zig
        p.lua
        p.nix
        p.json
        p.yaml
        p.toml
        p.markdown
        p.markdown_inline
        p.bash
        p.html
        p.css
        p.python
        p.go
        p.vim
        p.vimdoc
        p.regex
        p.c
        p.cpp
        p.java
        p.svelte
        p.graphql
        p.dockerfile
      ]))

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

    initLua =
      lua ./lua/options.lua
      + lua ./lua/keymaps.lua
      + lua ./lua/diagnostics.lua
      + lua ./lua/treesitter.lua
      + lua ./lua/lsp.lua
      + lua ./lua/plugins/cmp.lua
      + lua ./lua/plugins/telescope.lua
      + lua ./lua/plugins/neo-tree.lua
      + lua ./lua/plugins/gitsigns.lua
      + lua ./lua/plugins/lualine.lua
      + lua ./lua/plugins/which-key.lua
      + lua ./lua/plugins/indent-blankline.lua
      + lua ./lua/plugins/comment.lua
      + lua ./lua/plugins/autopairs.lua
      + lua ./lua/plugins/conform.lua
      + lua ./lua/plugins/lint.lua
      + lua ./lua/plugins/trouble.lua
      + lua ./lua/plugins/surround.lua
      + lua ./lua/plugins/dap.lua;
  };
}
