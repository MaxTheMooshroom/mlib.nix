{
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    # mlib.url = "github:MaxTheMooshroom/mlib.nix";

    # nixpkgs.url = "github:NixOS/nixpkgs/25.11";
  };

  outputs =
    { flake-parts, ... }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } (
      { lib, ... }:
      {
        systems = [ ];
        # systems = lib.systems.flakeExposed;

        imports = [
          # inputs.mlib.flakeModules.moduleArg-mlib
          # inputs.mlib.flakeModules.perSystem-packageSets
          # inputs.mlib.flakeModules.perSystem-tests
          # inputs.mlib.flakeModules.perSystem-checksFromTests
        ];

        flake = {
          # ...
        };

        perSystem =
          # pkgs,
          { ... }:
          {
            # formatter = pkgs.nixfmt-tree;

            # packages = {};

          };
      }
    );
}
