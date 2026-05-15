{ lib, lib', ... }:
let
  types' = lib'.types;

  inherit (lib)
    types
    mkOption
    mkOptionType
    ;

  inherit (lib'.trivial)
    isImportable
    updateAttrsWith
    ;

  function = mkOptionType {
    name = "function";
    description = "nix function";
    descriptionClass = "noun";
    check = lib.isFunction;
  };

  importable = types.anything // {
    check = isImportable;
  };

  importedAs = types.coercedTo importable builtins.import;
  fixedPointOf = types.coercedTo types'.function lib.fix;

  package-function = importedAs
    (updateAttrsWith
      (types.functionTo types.package)
      (old: {
        name = "package-function";
        check = x: old.check x && (lib.functionArgs x) != {};
      })
    );

  packageSet-member = types.mkOptionType {
    name = "packageSet-member";
    description = "a member of a packageSet, either a package or a nested packageSet";

    check = x: lib.isAttrs x && (
      (x.type or null == "derivation")
      || types'.packageSet.check x
    );
  };

  # packageSet-member = types.oneOf [
  #   types.package
  #   types'.packageSet
  # ];

  packageSet = types.submodule {
    freeformType = types'.packageSet-member;

    options = {
      _type = mkOption {
        type = types.str;
      };

      packageSet = mkOption { type = types'.function; };

      callPackage     = mkOption { type = types'.function; };
      callPackageSet  = mkOption { type = types'.function; };
      overridePackage = mkOption { type = types'.function; };
      overrideSet     = mkOption { type = types'.function; };

      # compat functions
      overrideScope = mkOption { type = types'.function; };
      newScope      = mkOption { type = types'.function; };
      packages      = mkOption { type = types'.function; };
    };

    config = {
      _type = lib.mkForce "pkg-set";
    };
  };

  strLike = mkOptionType {
    name = "string-like";
    description = "string-like value";
    descriptionClass = "noun";
    check = lib.isStringLike;
    merge = lib.options.mergeEqualOption;
  };

  coercedStr =
    types.coercedTo
      types'.strLike
      builtins.toString
      types.str;
in
{
  inherit
    coercedStr
    fixedPointOf
    function
    importable
    importedAs
    package-function
    packageSet
    packageSet-member
    strLike
    ;
}
