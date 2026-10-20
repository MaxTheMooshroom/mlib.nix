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
                [ (config.flake.name or "flake") "check-github" ]
              ;

            buildInputs = [ pkgs.act ];

            src =
              builtins.filterSource
                (_path: _: _path == ".github")
                inputs.self.outPath
              ;

            checkPhase =
              /* bash */
              ''
                act --validate --strict -C "$src"
              ''
              ;
          }
          ;
    }
    ;
}
