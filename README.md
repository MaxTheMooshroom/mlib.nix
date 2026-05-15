
# mlib

This is a personal collection of nix lib functions, modeled after nixpkgs' lib.

## Quickstart

```nix
{
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    mlib.url = "github:MaxTheMooshroom/mlib.nix";
  };

  outputs = { flake-parts, mlib, ... }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } ({ lib, ... }: {
      systems = lib.systems.flakeExposed;

      imports = [ inputs.mlib.flakeModules.perSystem.packageSets ];

      perSystem = { pkgs, mlib, ... }: {
        packageSets.basic = mlib.lib.
      };
    });
}
```

