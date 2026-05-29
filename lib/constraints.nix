{ lib, lib', ... }:
with builtins;
let
  trivial' = lib'.trivial;
in
{
  satisfiesAll = lib.flip (trivial'.turn all trivial'.swap);
  satisfiesAny = lib.flip (trivial'.turn any trivial'.swap);
}
