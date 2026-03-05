# Brave browser with declarative extensions.
{ lib, ... }:
{
  imports = [
    ./extensions.nix # Declarative extension install list
  ];

  programs.brave = {
    enable = true;
  };

  # Launcher currently uses Brave-Browser-Recovery profile; mirror HM-managed
  # extension manifests so declarative extensions load in that profile too.
  home.activation.braveRecoveryExternalExtensions = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    base_dir="$HOME/.config/BraveSoftware"
    source_dir="$base_dir/Brave-Browser/External Extensions"
    target_dir="$base_dir/Brave-Browser-Recovery/External Extensions"

    mkdir -p "$base_dir/Brave-Browser-Recovery"

    if [ -e "$target_dir" ] || [ -L "$target_dir" ]; then
      rm -rf "$target_dir"
    fi

    if [ -d "$source_dir" ]; then
      ln -s "$source_dir" "$target_dir"
    fi
  '';
}
