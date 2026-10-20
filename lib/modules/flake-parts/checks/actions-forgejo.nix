{ lib, lib', ... }:
{ inputs, config, ... }:
{
  imports = [ ./name.nix ];

  config.perSystem =
    { pkgs, ... }:
    {
      checks.actions-github =
        pkgs.stdenv.mkDerivation
          {
            name =
              builtins.concatStringsSep
                "-"
                [ (config.flake.name or "flake") "check-forgejo" ]
              ;

            buildInputs = [ pkgs.forgejo-runner ];

            src =
              builtins.filterSource
                (_path: _: _path == ".forgejo")
                inputs.self.outPath
              ;

            checkPhase =
              /* bash */
              ''
                forgejo-runner validate --directory "$src"
              ''
              ;
          }
          ;
    }
    ;
}
