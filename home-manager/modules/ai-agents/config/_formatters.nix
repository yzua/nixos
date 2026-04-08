# Formatter registry — single source of truth for tool→extensions→command.
#
# Used by both Claude hooks (_claude-hooks.nix) and Gemini hooks (models.nix).

let
  formatters = [
    {
      tool = "biome";
      extensions = [
        "js"
        "jsx"
        "ts"
        "tsx"
        "mjs"
        "cjs"
        "json"
        "jsonc"
        "css"
        "scss"
        "less"
        "graphql"
        "gql"
      ];
      command = "biome check --write";
    }
    {
      tool = "rustfmt";
      extensions = [ "rs" ];
      command = "rustfmt";
    }
    {
      tool = "zig";
      extensions = [
        "zig"
        "zon"
      ];
      command = "zig fmt";
    }
    {
      tool = "gofmt";
      extensions = [ "go" ];
      command = "gofmt -w";
    }
    {
      tool = "nixfmt";
      extensions = [ "nix" ];
      command = "nixfmt";
    }
    {
      tool = "ruff";
      extensions = [
        "py"
        "pyi"
      ];
      command = "ruff format";
    }
    {
      tool = "prettier";
      extensions = [
        "md"
        "mdx"
        "yaml"
        "yml"
        "html"
        "vue"
        "svelte"
        "astro"
      ];
      command = "prettier --write";
    }
  ];
in
{
  inherit formatters;

  mkClaudeFormatterHooks =
    mkFormatterHook: map (f: mkFormatterHook { inherit (f) tool extensions command; }) formatters;

  geminiCaseBranches = builtins.concatStringsSep "\n                    " (
    map (
      f:
      let
        extPattern = builtins.concatStringsSep "|" (map (e: "*.${e}") f.extensions);
      in
      ''${extPattern}) command -v ${f.tool} >/dev/null 2>&1 && ${f.command} "$FILE_PATH" 2>/dev/null ;;''
    ) formatters
  );
}
