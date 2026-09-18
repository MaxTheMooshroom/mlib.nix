{ lib, lib', ... }:
with builtins;
let
  trivial' = lib'.trivial;
  constraints' = lib'.constraints;
in
{
  #? satisfiesAll :: [(A -> bool)] -> A -> bool;
  satisfiesAll = lib.flip (trivial'.turn all trivial'.swap);
  #? satisfiesAny :: [(A -> bool)] -> A -> bool;
  satisfiesAny = lib.flip (trivial'.turn any trivial'.swap);

  #? satisfiesEither :: (A -> bool) -> (A -> bool) -> A -> bool;
  satisfiesBoth = trivial'.turn2 constraints'.satisfiesAll lib'.lists.tuple;
  #? satisfiesBoth :: (A -> bool) -> (A -> bool) -> A -> bool;
  satisfiesEither = trivial'.turn2 constraints'.satisfiesAny lib'.lists.tuple;
}
