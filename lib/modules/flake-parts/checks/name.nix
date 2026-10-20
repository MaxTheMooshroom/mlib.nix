{ ... }:
{ lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  options.name =
    mkOption
      {
        type = types.str;
        description = "the flake's name";
        default = "";
      }
      ;
}
