{ lib, lib', ... }:
let
  validFixedPoint = lib'.asserts.fixed-points.validate;

  # inherit (lib'.trivial)
  #   const
  #   getLevenshteinFast
  #   negate
  #   pipe
  #   ;

  orAllValues = lib.const (builtins.any lib.id);
in
{
  #? composeOverridesOf :: F1 -> F2 -> (set -> )
  #? F1 :: { __functor :: (F1 -> set -> F2), override :: (set -> F1), ... }
  #? F2 :: { __functor :: (F2 -> set -> R), override :: (set -> F2), ... }
  composeOverridesOf =
    f1: f2: default-f2-args:
    let
      f1-args = lib.functionArgs f1.override;
      f2-args = lib.functionArgs f2.override;
    in
      {
        inherit f1 f2 f1-args f2-args default-f2-args;

        __functionArgs =
          builtins.zipAttrsWith
            orAllValues
            [f1-args f2-args]
          ;

        __functor =
          { f1, f1-args, f2, f2-args, default-f2-args, ... }:
          { ... }@args:
          let
            args-1 = builtins.intersectAttrs f1-args args;
            args-2 = default-f2-args // (builtins.intersectAttrs f2-args args);
          in
            if    args-1 != {}
            then  f1.override args-1 args-2
            else
              if    args-2 != {}
              then  f2.override args-2
              else  f2
          ;
      }
      ;

  callPackageFunctionWith =
    autoArgs: fn: pkg-args:
    let pkg-fn = lib.callPackageWith autoArgs fn pkg-args; in
    {
      inherit pkg-fn;

      __functionArgs = lib.functionArgs pkg-fn;

      __functor =
        { pkg-fn, ... }:
        args:
        let
          pkg = pkg-fn args;
        in
          pkg
        //
          { override = lib'.customization.composeOverridesOf pkg-fn pkg args; }
        ;
    }
    ;

  /**
    Construct a recursive attribute-set ("package-set") of packages and/or
    nested package-sets, using a fixed-point operator over a package-function.

    A fixed-point function is a function whose result can be partially
    evaluated by providing the result as the argument. That is, `x -> x` for
    some lazily-evaluated value `x`. An example would be
    `self: { a = 0; b = self.a + 5; }`. If you tried to strictly evaluate
    the function's result, you'd get an infinite-recursion error. However,
    by evaluating the resulting attribute-set bit-by-bit, there are no
    dependency issues.

    A package-function is a function with the form
    `AttrSet -> (Package | Any)`, where `Package` has a "type" attribute with
    the value `"derivation"`. The result of a package-function is not
    technically guaranteed to be a package, bnut it is generally assumed to be.

    Composing a fixed-point over a package-function is non-trivial and cannot
    be done using separate actions for each component. As such, instead of
    using a fixed-point evaluated using the result of a package function, they
    must be evaluated together using a "package-set-function", which describes
    the entire composition of the fixed-point operator over the
    package-function.

    The arguments passed to the package-function component of the
    package-set-function are derived first from a set of default arguments,
    then from a second set of direct arguments / overrides. If the
    package-function has a required parameter that is not present on either
    attribute-set, then an error occurs.

    # Arguments

    autoArgs

    : 1\. (`AttrSet`)
        The "default" arguments provided to the inner package-function.

    f

    : 2\. (`Path | (a -> pkgs -> a)`)
       The package-set-function, as described above.

    args

    : 3\. (`AttrSet`)
       An attrset of arguments to pass to the inner package-function.

    # Output

    `callPackageSetWith` returns a package-set (as described above) using
    a set of default arguments (`autoArgs`) to pass to the inner
    package-function of the package-set-function `f` and each of the resulting
    package-set's nested package-sets, the package-set-function `f`, and a set
    of arguments and/or overrides provided to `f`'s inner package-function.

    # Type

    ```
    callPackageSetWith :: AttrSet
        -> (Path | (a -> AttrSet -> a))
        -> AttrSet
        -> PackageSet

    PackageSet :: {
      callPackage :: (Path | (AttrSet -> a)) -> AttrSet -> a,
      callPackageSet :: (Path | (PackageSet -> pkgs -> PackageSet)) -> PackageSet -> (autoArgs // args) -> PackageSet,
      overridePackage :: AttrSet -> self,
      overrideSet :: (PackageSet -> PackageSet -> AttrSet) -> PackageSet,
      packageSet :: a -> pkgs -> a,

      # scope-compat attributes
      packages :: self.packageSet,
      overrideScope :: self.overrideSet,
      newScope :: (AttrSet -> scope),
    }
    ```

    - `callPackage` (`(Path | (AttrSet -> a)) -> AttrSet -> a`)

      A function that:

      1. Takes a "package-function" `p`, or an expression that
        evaluates to one when passed to `builtins.import`, which
        takes an attribute set and returns a value `a` of
        arbitrary type, but typically a package.
      2. Takes an attribute set `args` with explicit attributes
        to pass to `p`.
      3. Calls `f` with attributes from the original attribute set
        `attrs`

    - `callPackageSet` (`(Path | (PackageSet -> (autoArgs // args) -> PackageSet)) -> PackageSet -> (autoArgs // args) -> PackageSet`).

      A function that uses the current package-set to create a new, nested
      package-set. It is a partially-parameterized form of the current
      function `callPackageSetWith` that uses the current set's `autoArgs`,
      updated with `args`, as the `autoArgs` parameter of nested package-sets'
      `callPackage` and `callPackageSet` functions.

    # TODO

    document __internal: __internal is a list of package-set items that are
    removed from the final result of the package-set, but still available to
    self.callPackage and self.callPackageSet.

    ```
    callPackageSetWith {} (self: { dep, }: {  })
    ````
  */
  callPackageSetWith =
    autoArgs: f: args:
    let
      f' = if lib.isFunction f then f else import f;
    in
    assert validFixedPoint f';
    let
      args' = autoArgs // args;

      self =
        let
          args'' = args' // self;

          callPackage = lib.callPackageWith args'';
          callPackageFunction = lib'.customization.callPackageFunctionWith args'';

          package = (lib.callPackageWith args' (f' self) { });

          set-members = {
            _type = "pkg-set";

            inherit callPackage callPackageFunction;
            callPackageSet = lib'.callPackageSetWith args'';
            overridePackage = x: lib'.callPackageSetWith autoArgs f' (args // x);
            overrideSet = g: lib'.callPackageSetWith autoArgs (lib.extends g f') args;
            packageSet = f';

            # compat for infra that expects a scope.

            packages = self.packageSet;
            overrideScope = self.overrideSet;
            newScope = x: lib.callPackageWith (args' // self // x);
          };
        in
        (removeAttrs package ([ "__internal" ] ++ (package.__internal or [ ]))) // set-members;
    in
    removeAttrs self [
      "override"
      "overrideDerivation"
    ];
}
