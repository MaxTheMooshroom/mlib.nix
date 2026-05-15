lib: lib.makeExtensible
(self:
  let
    callLib = path: args: import path (args // {
      inherit lib callLib callLib';

      lib' = self;
    });

    callLib' = lib.flip callLib {};
  in
  {
    asserts = callLib' ./asserts.nix;
    attrsets = callLib' ./attrsets.nix;
    cli = callLib' ./cli.nix;
    customization = callLib' ./customization.nix;
    debug = callLib' ./debug.nix;
    derivations = callLib' ./derivations.nix;
    fetchers = callLib' ./fetchers.nix;
    fileset = callLib' ./fileset.nix;
    filesystem = callLib' ./filesystem.nix;
    fixed-points = callLib' ./fixed-points.nix;
    flakes = callLib' ./flakes.nix;
    generators = callLib' ./generators.nix;
    gvariant = callLib' ./gvariant.nix;
    kernel = callLib' ./kernel.nix;
    licenses = callLib' ./licenses.nix;
    lists = callLib' ./lists.nix;
    meta = callLib' ./meta.nix;
    misc = callLib' ./misc.nix;
    modules = callLib' ./modules;
    network = callLib' ./network.nix;
    options = callLib' ./options.nix;
    path = callLib' ./path.nix;
    sources = callLib' ./sources.nix;
    source-types = callLib' ./source-types.nix;
    strings = callLib' ./strings.nix;
    strings-with-deps = callLib' ./strings-with-deps.nix;
    systems = callLib' ./systems.nix;
    trivial = callLib' ./trivial.nix;
    types = callLib' ./types.nix;
    versions = callLib' ./versions.nix;

    inherit (self.trivial)
      const
      eq
      neq
      swap
      turn
      ;

    inherit (self.customization)
      callPackageSetWith
      ;
  })
