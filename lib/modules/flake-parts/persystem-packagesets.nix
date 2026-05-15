{ lib, lib', ... }:
{ flake-parts-lib, ... }:
flake-parts-lib.mkTransposedPerSystemModule {
  name = "packageSets";
  option = lib.mkOption {
    type = lib.types.lazyAttrsOf lib'.types.packageSet;
    default = { };
    description = ''
      A set of package-sets, which are sets of packages and/or nested
      package-sets.
    '';
  };
  file = ./persystem-packagesets.nix;
}
