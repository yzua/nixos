# Custom utility scripts added to user PATH.

{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    (writeShellScriptBin "nvidia-fans" ''
      exec ${config.home.homeDirectory}/System/scripts/hardware/nvidia-fans.sh "$@"
    '')
    (writeShellScriptBin "zellij-main" ''
            set -euo pipefail

            for layout_path in "$HOME"/.cache/zellij/*/session_info/main/session-layout.kdl; do
              [[ -e "$layout_path" ]] || continue

              if ! ${pkgs.python3}/bin/python3 - "$layout_path" <<'PY'
      import pathlib
      import sys

      path = pathlib.Path(sys.argv[1])
      data = path.read_bytes()

      if not data:
          raise SystemExit(1)
      if b"\x00" in data:
          raise SystemExit(1)

      try:
          text = data.decode("utf-8")
      except UnicodeDecodeError:
          raise SystemExit(1)

      if "layout" not in text:
          raise SystemExit(1)
      PY
              then
                rm -rf "$(dirname "$layout_path")"
              fi
            done

            exec ${pkgs.zellij}/bin/zellij attach --create main "$@"
    '')
  ];
}
