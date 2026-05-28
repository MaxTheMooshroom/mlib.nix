{ lib, lib', ... }:
{
  mkFlake =
    { inputs, specialArgs ? {}, ... }@args:

    assert lib.assertMsg
      (inputs ? flake-parts)
      "Cannot call inputs.mlib.lib.mkFlake without a 'flake-parts' input!";

    inputs.flake-parts.lib.mkFlake (args // {
      inherit inputs;
      specialArgs = specialArgs // {
        mlib = inputs.mlib.lib or lib';
      };
    });
}
