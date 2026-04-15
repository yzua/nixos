# Color conversion utilities for Glance theming.

let
  hexChar =
    c:
    {
      "0" = 0;
      "1" = 1;
      "2" = 2;
      "3" = 3;
      "4" = 4;
      "5" = 5;
      "6" = 6;
      "7" = 7;
      "8" = 8;
      "9" = 9;
      "a" = 10;
      "b" = 11;
      "c" = 12;
      "d" = 13;
      "e" = 14;
      "f" = 15;
    }
    .${c};

  hexByte = s: hexChar (builtins.substring 0 1 s) * 16 + hexChar (builtins.substring 1 1 s);

  round = x: builtins.floor (x + 0.5);
in
# Convert hex (#RRGGBB) to Glance's decimal HSL format ("H S L").
hex:
let
  h = builtins.substring 1 6 hex;
  r = hexByte (builtins.substring 0 2 h);
  g = hexByte (builtins.substring 2 2 h);
  b = hexByte (builtins.substring 4 2 h);

  rn = r / 255.0;
  gn = g / 255.0;
  bn = b / 255.0;

  max = if rn > gn then (if rn > bn then rn else bn) else (if gn > bn then gn else bn);
  min = if rn < gn then (if rn < bn then rn else bn) else (if gn < bn then gn else bn);
  delta = max - min;

  l = (max + min) / 2.0;

  s =
    if delta == 0 then
      0.0
    else if l <= 0.5 then
      delta / (max + min)
    else
      delta / (2.0 - max - min);

  rawH =
    if delta == 0 then
      0.0
    else if max == rn then
      (gn - bn) / delta + (if gn < bn then 6.0 else 0.0)
    else if max == gn then
      (bn - rn) / delta + 2.0
    else
      (rn - gn) / delta + 4.0;
in
"${toString (round (rawH * 60.0))} ${toString (round (s * 100.0))} ${toString (round (l * 100.0))}"
