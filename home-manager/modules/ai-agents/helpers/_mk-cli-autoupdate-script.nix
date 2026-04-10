{
  pkgs,
}:
{
  binary,
  npmPackage,
  label,
}:
pkgs.writeShellScript "${binary}-autoupdate" ''
  if ! command -v ${binary} >/dev/null 2>&1; then
    exit 0
  fi

  binary_path="$(readlink -f "$(command -v ${binary})")"

  if [[ "$binary_path" == *"/.bun/install/global/"* ]]; then
    ${pkgs.bun}/bin/bun install -g ${npmPackage}@latest
  elif [[ "$binary_path" == *"/.npm-global/"* ]]; then
    ${pkgs.nodejs}/bin/npm install -g ${npmPackage}@latest
  elif command -v bun >/dev/null 2>&1; then
    bun install -g ${npmPackage}@latest
  elif command -v npm >/dev/null 2>&1; then
    npm install -g ${npmPackage}@latest
  else
    echo "No supported package manager found for ${label} auto-update"
    exit 1
  fi

  echo "Updated ${label}"
''
