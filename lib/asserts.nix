{ lib, lib' }:
{
  validFixedPoint = f: lib.assertMsg (lib.functionArgs f == {}) ''
    You passed a function with destructured parameters to `makePackageSet`,
    `makePackageSetFrom`, or `<package-set>.newSet`. The fixed-point of the
    function is computed, so the provided function is expected to be a
    fixed-point operator. Because destructured parameters require strict
    evaluation of the destructured attrset, and fixed-points are
    self-dependent, this creates an infinite loop.
  '';
}
