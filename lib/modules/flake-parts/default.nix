{ callLib', ... }:
{
  perSystem =
    {
      moduleArgs = { };

      packageSets = callLib' ./persystem-packagesets.nix;

      tests = callLib' ./persystem-tests.nix;

      checksFromTests = callLib' ./persystem-checks-from-tests.nix;

      checks =
        {
          forgejo = callLib' ./checks/actions-forgejo.nix;
          github = callLib' ./checks/actions-github.nix;
        }
        ;
    }
    ;
}
