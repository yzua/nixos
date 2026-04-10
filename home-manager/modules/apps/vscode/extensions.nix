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
in
{
  programs.vscode.profiles.default.extensions = builtInExtensions ++ marketplaceExtensions;
}
