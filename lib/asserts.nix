{ lib, lib', ... }:
{
  fixed-points = lib.fix' (self: {
    validate = f: lib.assertMsg (lib.functionArgs f == {}) ''
      You passed a function with destructured parameters to a function
      expecting a fixed-point operator. Fixed-points are validated by checking
      that the function doesn't use a set-pattern (eg. `{ foo, bar, ... }: {}`)
      checks its validity using `mlib.asserts.fixed-points.validate`, which
      . The fixed-point of the
      function is computed, so the provided function is expected to be a
      fixed-point operator. Because destructured parameters require strict
      evaluation of the destructured attrset, and fixed-points are
      self-dependent, this creates an infinite loop.
    '';

    /**
      Wrap a fixed-point operator (the function that produces a fixed-point)
      with a list of asserts such that passing the result of this function
      to `lib.fix` produces the exact same result as passing `fp` to `lib.fix`,
      except that the asserts must pass, else an assertion error occurs.

      # Arguments

      `asserts`
      : 1\. The list of assertions, each of the form `fixed-point -> bool`.

      `fp`
      : 2\. The fixed-point operator to wrap.

      # Type

      ```
      wrapWithAsserts :: [FixedPoint -> bool] -> FixedPointOperator -> FixedPoint
      ```
    */
    wrapWithAsserts = asserts: fp:
      self:
        let
          fp' = fp self;
        in
          assert builtins.all (lib'.trivial.swap fp') asserts;
          fp';
  });

  packageSets = lib.fix' (self: {
    validate = fp:
      assert lib'.asserts.fixed-points.validate fp;
      let fp' = lib.fix fp; in
        lib.assertMsg (lib.functionArgs fp' != {}) ''
          A packageset-function is a fixed-point operator over the resulting
          attribute-set of a package-function, which looks like
          `self: { foo, bar, ... }: { /* ... */ }`.

          You passed a packageset-function to another function that validates
          them with `mlib.asserts.packageSets.validate`, which uses
          `lib.functionArgs` to determine the validity of both fixed-point
          operators and of package-functions. The inner package-function
          provided either doesn't use a set-pattern
          (destructured arguments (`{ foo, bar, ... }: /* ... */`))
          or it uses an empty set-pattern
          (`{}: /* ... */` or `{...}: /* ... */`), which are not detectable by
          builtins.functionArgs (which is used by lib.functionArgs).

          While not technically invalid for package-functions, this makes them
          impossible to validate as package-functions.

          If you're trying to create a packageset with no parameters for its
          package-function, you'd probably be better served by
          [nixpkgs.lib.makeScope](https://noogle.dev/f/lib/makeScope/).
        '';

    /**
      Wrap a packageset-function (a fixed-point operator over the attrset
      result of a package-function) with a list of asserts such that passing
      the result of this function to `mlib.callPackageSetWith` produces the
      exact same result as passing `fp` to `mlib.callPackageSetWith`,
      except that the asserts must pass, else an assertion error occurs.

      # Arguments

      `asserts`
      : 1\. The list of assertions, each of the form `fixed-point -> bool`.

      `psf`
      : 2\. The packageset-function to wrap.

      # Type

      ```
      wrapWithAsserts :: [set -> bool] -> FixedPointOperator -> set -> (Package | Any)
      ```
    */
    wrapWithAsserts = asserts: psf:
      self:
        let g = psf self; in {
          __functionArgs = lib.functionArgs g;
          __functor = _: args:
            let result = g args; in
              assert builtins.all (lib'.trivial.swap result) asserts;
              result;
      };
  });
}
