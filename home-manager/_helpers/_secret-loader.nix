# Shared bash function for loading sops secrets from /run/secrets/.
# Used by zsh init (functions.nix) and standalone agent wrapper scripts (android-re/_launchers.nix).
# Located in home-manager/_helpers/ because it is only used by HM modules.

let
  loadSecretFn = ''
    _load_secret() {
      local key_file="/run/secrets/$1"
      if [[ ! -f "$key_file" ]]; then
        echo "Error: $key_file not found. Run 'just nixos' to decrypt secrets." >&2
        return 1
      fi
      cat "$key_file"
    }
  '';
in
{
  inherit loadSecretFn;
}
