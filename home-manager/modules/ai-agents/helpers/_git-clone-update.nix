# Generates a Bash snippet that clones or updates a git repo under ~/.local/share/.
{ pkgs }:

{ name, url }:

''
  if [[ -d "$HOME/.local/share/${name}/.git" ]]; then
    echo "📦 Updating ${name}..."
    ${pkgs.git}/bin/git -C "$HOME/.local/share/${name}" pull --ff-only 2>/dev/null || true
  else
    echo "📦 Cloning ${name}..."
    rm -rf "$HOME/.local/share/${name}"
    ${pkgs.git}/bin/git clone --depth 1 ${url} "$HOME/.local/share/${name}" 2>/dev/null || true
  fi
''
