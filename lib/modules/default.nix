{ callLib', ... }:
{
  nixpkgs = {};

  flake-parts = callLib' ./flake-parts;
}
