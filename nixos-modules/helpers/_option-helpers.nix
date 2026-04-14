# Shared option constructors for NixOS modules.

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
}
