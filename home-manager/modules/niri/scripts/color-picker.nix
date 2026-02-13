{ pkgsStable, ... }:
pkgsStable.writeScriptBin "color-picker" ''
  #!${pkgsStable.bash}/bin/bash
  color=$(${pkgsStable.grim}/bin/grim -g "$(${pkgsStable.slurp}/bin/slurp -p)" -t ppm - \
    | ${pkgsStable.imagemagick}/bin/magick - -format '%[hex:p{0,0}]' info:-)
  if [[ -n "$color" ]]; then
    echo "#$color" | ${pkgsStable.wl-clipboard}/bin/wl-copy --trim-newline
    ${pkgsStable.libnotify}/bin/notify-send "Color Picker" "#$color copied to clipboard"
  fi
''
