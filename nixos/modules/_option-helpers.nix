# Shared option constructors for common schemas.
{ lib }:

{
  mkBoolOption =
    default: example: description:
    lib.mkOption {
      type = lib.types.bool;
      inherit default example description;
    };

  mkNullableOption =
    type: default: example: description:
    lib.mkOption {
      type = with lib.types; nullOr type;
      inherit default example description;
    };
}
