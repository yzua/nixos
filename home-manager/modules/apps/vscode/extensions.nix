# VS Code extensions (nixpkgs + marketplace).

{
  pkgs,
  ...
}:

let
  marketplace = pkgs.vscode-utils.buildVscodeMarketplaceExtension;
  mkMarketplaceExtension = mktplcRef: marketplace { inherit mktplcRef; };
  marketplaceRefs = import ./_marketplace-refs.nix;
  builtInExtensions = import ./_builtin-extensions.nix { inherit pkgs; };
  marketplaceExtensions = map mkMarketplaceExtension marketplaceRefs;

  # Upstream hash for claude-code 2.1.114 is stale — override with correct one
  claude-code-fix = pkgs.vscode-extensions.anthropic.claude-code.overrideAttrs (_: {
    src = _.src.overrideAttrs (_: {
      outputHash = "sha256-TfVradC9ZjfLBp8QvZ0AptCS9j2ogzSlsRXxksp+N9I=";
    });
  });

  replaceClaudeCode = builtins.map (
    ext: if ext.pname or "" == "vscode-extension-anthropic-claude-code" then claude-code-fix else ext
  );
in
{
  programs.vscode.profiles.default.extensions = replaceClaudeCode (
    builtInExtensions ++ marketplaceExtensions
  );
}
