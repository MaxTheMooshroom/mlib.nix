{
  inputs = {
    nixpkgs-lib.url = "github:nix-community/nixpkgs.lib";

    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs-lib";

    lib = { flake = false; url = ./lib/top-level.nix; };
  };

  outputs = { self, flake-parts, ... }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } ({ lib, ... }: {
      systems = [];

      imports = [ flake-parts.flakeModules.flakeModules ];

      flake.lib = import inputs.lib lib;

      flake.flakeModules.default = { lib, ... }: {
        _module.args.mlib = import inputs.lib lib;
      };

      flake.overlays.nixpkgs = final: prev: {
        lib' = import inputs.lib prev.lib;

        /**
          Construct a "package-set", an attribute set of packages and/or
          nested package-sets, from functions that take arguments from
          `pkgs` and/or from the arguments used to construct that same
          package-set.

          # Inputs

          1. `f` (`Path | (a -> pkgs -> a)`)

             Either a fixed-point function-operator over a package-function,
             or a value that evaluates to one when passing it to
             `builtins.import`.

          2. `args` (`AttrSet`)

             An attrset of values to pass to `f`'s package-function,
             either because they're missing from `pkgs` or because you're
             overriding one or more values of `pkgs`.

          # Output

          `callPackageSet` returns an attribute set with a specific
          `PackageSet` form, and the final attributes produced by `f`:

          ```
          PackageSet :: self :: {
            callPackage :: (Path | (AttrSet -> a)) -> AttrSet -> a,
            callPackageSet :: (Path | (PackageSet -> pkgs -> PackageSet)) -> PackageSet -> pkgs -> PackageSet,
            overrideSet :: (PackageSet -> PackageSet -> AttrSet) -> PackageSet,
            packageSet :: a -> pkgs -> a,

            # scope-compat atrtibutes
            packages :: self.packageSet,
            overrideScope :: self.overrideSet,
          }
          ```
        */
        callPackageSet = final.lib'.callPackageSetWith final.newScope;
      };
    });
}
