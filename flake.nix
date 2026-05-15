{
  inputs = {
    nixpkgs-lib.url = "github:nix-community/nixpkgs.lib";
    # nixpkgs-lib.url = "github:NixOS/nixpkgs/25.11?dir=lib";

    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs-lib";

    lib = { flake = false; url = ./lib/top-level.nix; };
  };

  outputs = { self, flake-parts, ... }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } ({ config, lib, ... }: {
      systems = [];

      imports = [ flake-parts.flakeModules.flakeModules ];

      flake.lib = import inputs.lib lib;

      flake.flakeModules =
        let
          flattenAttrs =
            let
              flatten = prefix: attrs:
                builtins.foldl'
                  (acc: name:
                    let
                      value = attrs.${name};
                      key =
                        if    prefix == ""
                        then  name
                        else  "${prefix}-${name}";
                    in
                      if    builtins.isAttrs value && value != {}
                      then  acc // flatten key value
                      else  acc // { ${key} = value; }
                  )
                  {}
                  (builtins.attrNames attrs);
            in
              flatten "";
        in flattenAttrs config.flake.lib.modules.flake-parts;
    });
}
