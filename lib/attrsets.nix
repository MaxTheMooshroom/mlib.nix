{ lib, lib', ... }:
let
  inherit (lib)
    filterAttrs
    mapAttrs'
    mergeAttrs
    nameValuePair
    ;

  attrsets' = lib'.attrsets;
in
{
  prefixAttrNames = prefix:
    let key = if prefix != "" then "${prefix}-" else prefix; in
    mapAttrs' (name: value: nameValuePair "${key}${name}" value);

  # mergeAllAttrs

  flattenAttrs =
    let
      toMerge = (filterAttrs (lib'.const builtins.isAttrs));
      noMerge = (filterAttrs (lib'.const lib'.trivial.notAttrs));

      mergeAttrs = lib'.turn
        (lib.mapAttrsToList attrsets'.prefixAttrNames)
        toMerge;
    in
      attrs:
        builtins.listToAttrs (mergeAttrs attrs)
        // (noMerge attrs);
}
