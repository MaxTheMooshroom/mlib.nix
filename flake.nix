{
  inputs = {
    nixpkgs-lib.url = "github:nix-community/nixpkgs.lib";

    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs-lib";

    lib = { flake = false; url = ./lib/top-level.nix; };
  };

  outputs = { self, flake-parts, ... }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } ({ config, lib, mlib, ... }: {
      systems = [];

      imports = [
        flake-parts.flakeModules.flakeModules
        ({ config, ... }: { _module.args.mlib = config.flake.lib; })
      ];

      flake.lib = import inputs.lib lib;

      flake.flakeModules =
        let
          prefixAttrNames = prefix:
            lib.mapAttrsToList (
              name: value: { inherit value; name = "${prefix}-${name}"; }
            );

          mergeAttrNamesDown =
            mlib.turn builtins.listToAttrs (
              mlib.turn builtins.concatLists (
                lib.mapAttrsToList (
                  name: value:
                    if    builtins.isAttrs value
                    then  prefixAttrNames name value
                    else  [{ inherit name value; }]
                )
              )
            );
        in mergeAttrNamesDown mlib.modules.flake-parts;
    });
}
