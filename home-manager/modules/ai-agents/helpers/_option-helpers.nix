# Shared option constructors for ai-agents modules.

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

  mkOptionNoDefault = type: description: lib.mkOption { inherit type description; };
  mkNullOrOption = type: description: mkTypedOption (lib.types.nullOr type) null description;
  mkBoolOption = default: description: mkTypedOption lib.types.bool default description;
  mkStrOption = default: description: mkTypedOption lib.types.str default description;
  mkIntOption = default: description: mkTypedOption lib.types.int default description;
  mkAttrsOption = default: description: mkTypedOption lib.types.attrs default description;
  mkAttrsOfStrOption =
    default: description: mkTypedOption (lib.types.attrsOf lib.types.str) default description;
  mkStrListOption =
    default: description: mkTypedOption (lib.types.listOf lib.types.str) default description;
  mkNullOrStrOption =
    default: description: mkTypedOption (lib.types.nullOr lib.types.str) default description;
  mkTypedOptionWith =
    type: default: description: extra:
    lib.mkOption ({ inherit type default description; } // extra);
}
