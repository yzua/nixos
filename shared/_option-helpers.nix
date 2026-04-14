# Shared option constructors for NixOS and Home Manager modules.
# Usage: import ../../shared/_option-helpers.nix { inherit lib; }

{ lib }:
let
  mkTypedOption =
    type: default: description:
    lib.mkOption {
      inherit type default description;
    };
in
{
  inherit mkTypedOption;

  mkBoolOption = default: description: mkTypedOption lib.types.bool default description;
  mkStrOption = default: description: mkTypedOption lib.types.str default description;
  mkIntOption = default: description: mkTypedOption lib.types.int default description;
  mkNullableOption =
    type: default: description:
    mkTypedOption (lib.types.nullOr type) default description;
  mkAttrsOption = default: description: mkTypedOption lib.types.attrs default description;
  mkAttrsOfStrOption =
    default: description: mkTypedOption (lib.types.attrsOf lib.types.str) default description;
  mkStrListOption =
    default: description: mkTypedOption (lib.types.listOf lib.types.str) default description;
  mkLinesOption = default: description: mkTypedOption lib.types.lines default description;
  mkNullOrStrOption =
    default: description: mkTypedOption (lib.types.nullOr lib.types.str) default description;
}
