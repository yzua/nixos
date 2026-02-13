{ pkgsStable, ... }:
pkgsStable.writeScriptBin "screenshot-annotate" ''
  #!${pkgsStable.bash}/bin/bash
  set -euo pipefail
  ${pkgsStable.grim}/bin/grim -g "$(${pkgsStable.slurp}/bin/slurp)" - | ${pkgsStable.swappy}/bin/swappy -f -
''
