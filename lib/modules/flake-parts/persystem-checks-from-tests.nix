{ lib, lib', ... }:
{ config, ... }:
{
  config.perSystem = { self', }: {
    checks = lib.mapAttrs (lib'.const (builtins.getAttr "all")) self'.tests;
  };
}
