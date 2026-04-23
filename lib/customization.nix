{ lib, lib' }:
let
  inherit (lib'.asserts)
    validFixedPoint
    ;
in
{
  /**
    Evaluate the fixed-point of a package-set using each of
    the following:

    1. The fixed-point package-function's operator.
    2. A scope of fallback values to use for missing parameters.
    3. A set of parameters and/or overrides.

    If `fn` is not a function, it is passed to `builtins.import`
    and the result of the import is used as the fixed-point
    operator instead.

    The operator's package-function is automatically called with
    the required arguments using a scope constructed by passing
    `args` to `toAutoArgs`.

    `callPackageSetWith` is intended to be partially
    parameterised as such:

    ```nix
    callPackageSet = callPackageSetWith pkgs.newScope;
    # or
    callPackageSet = callPackageSetWith (x: pkgs // x);
    package-sets = {
      foo = callPackage ./foo.nix { };
      set-bar = callPackageSet ./bar.nix { };
    };
    ```

    As `libfoo` is just a package, nothing special occurs here. See
    [lib.callPackageWith](https://noogle.dev/f/lib/callPackageWith/)
    for more information.

    `set-bar`, however, is a package-set (as determined by the use of
    `callPackageSet` instead of `callPackage`), so we'll cover that
    next.

    Package-sets are defined as fixed-point operators over a
    package-function, and take the following form:
    ```nix
    self: { ... }: {}
    ```

    The resulting package-set is the argument `self`, making
    package-sets recursive. For this reason the result must be lazy,
    [set-patterns]()
    are impossible to use

    Overrides or missing arguments can be supplied via `args` as such:

    `./bar.nix` example:
    ```nix
    self:
    { enableLibFoo ? false, ... }: {
      libfoo = if enableLibFoo then self.lib else null;
    }
    ```
    ```nix
    libbar = callPackageSet ./bar.nix {
      enableLibFoo = true;
    };
    ```

    Because the package-set's `libbar` expects `libfoo` as an input,
    and it is found as 

    # Inputs

    `toAutoArgs`

    : 1\. Function argument

    `fn`

    : 2\. Function argument

    `args`

    : 3\. Function argument

    # Type

    ```
    ImportedAs<E> ::= (value | import value) :: E

    AttrSetOf<T> :: { <name> :: T }

    callPackageSetWith ::
      AttrSetOf<Package | Any>
      -> ImportedAs<AttrSet -> a>
      -> AttrSetOf<Package | Any>
      -> a
    ```
  */
  callPackageSetWith = toAutoArgs: f: args:
    let
      f' =
        if    lib.isFunction f && lib.functionArgs f == {}
        then  f
        else  import f;
    in
    assert validFixedPoint f';
    let
      callPackage = toAutoArgs args;
      self = (callPackage (f' self) {}) // {
        inherit callPackage;
        _type = "pkg-set";
        callPackageSet = lib'.callPackageSetWith (x: toAutoArgs (self // args // x));
        overrideSet = g: lib'.callPackageSetWith toAutoArgs (lib.extends g f') args;
        packageSet = f';
        # aliases for compat with infra that expects a scope.
        packages = self.packageSet;
        overrideScope = self.overrideSet;
      };
    in
      builtins.removeAttrs self [ "overrideDerivation" ];
}
