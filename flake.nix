{
  inputs.flake-parts.url = "github:hercules-ci/flake-parts";

  outputs =
    { self, flake-parts, ... }@inputs:
    flake-parts.lib.mkFlake
      { inherit inputs; }
      (
        { lib, mlib, ... }:
        {
          systems = lib.systems.flakeExposed;

          imports =
            with flake-parts.flakeModules;
              [
                flakeModules
                partitions

                (
                  { config, ... }:
                  {
                    _module.args.mlib = config.flake.lib;
                  }
                )
              ];

          flake.lib = import ./lib lib;

          partitionedAttrs =
            {
              devShells = "dev";
              formatter = "dev";
            };

          flake.flakeModules =
            let
              prefixAttrNames =
                prefix:
                lib.mapAttrsToList
                  (
                    name: value:
                    {
                      inherit value;
                      name = "${prefix}-${name}";
                    }
                  );

              mergeAttrNamesDown =
                mlib.turn
                  builtins.listToAttrs
                  (
                    mlib.turn
                      builtins.concatLists
                      (
                        lib.mapAttrsToList
                          (
                            name: value:
                            if    builtins.isAttrs value
                            then  prefixAttrNames name value
                            else  [ { inherit name value; } ]
                          )
                      )
                  );
            in
              mergeAttrNamesDown mlib.modules.flake-parts;

          partitions.dev =
            {
              extraInputsFlake = ./dev;

              module =
                { inputs, ... }:
                {
                  perSystem =
                    { pkgs, ... }:
                    {
                      formatter = pkgs.nixfmt-tree;

                      devShells.default =
                        pkgs.mkShellNoCC
                          {
                            packages =
                              with pkgs;
                              [
                                nixfmt
                                nixfmt-tree
                                # ...
                              ];
                          };
                    };
                };
            };
        }
      );
}
