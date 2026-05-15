{ lib', callLib', ... }:
{
  perSystem = {
    moduleArgs = {
      # TODO: delete? is there justification to have mlib as a perSystem arg?
      #
      # mlib = { ... }: {
      #   perSystem = { ... }: {
      #     _module.args.mlib = lib';
      #   };
      # };
    };

    packageSets = callLib' ./persystem-packagesets.nix;
  };
}
