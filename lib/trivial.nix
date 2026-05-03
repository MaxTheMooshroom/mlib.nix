{ lib, lib' }:
let
  trivial' = lib'.trivial;

  inherit (lib.filesystem)
    pathIsDirectory
    pathIsRegularFile
    ;
in
{
  /**
    Check if 2 values are equal.

    # Type

    ```
    eq :: Any -> Any -> Bool
    ```

    # Examples

    Standard use is partial-parameterization, as such:

    ```
    isFoo = mlib.eq "foo";

    result = isFoo "bar"; # false
    ```
  */
  eq = a: b: b == a;
  neq = a: b: a != b;

  swap = x: f: f x;
  turn = f: f': x: f (f' x);

  /**
    call a function with a list of parameters.

    Parameter `f` only exists for this documentation to be discoverable.

    # Inputs

    `f`

    : 1\. The function to pass the arguments to. Takes any number
          of arguments (each of a type determined by `f` rather than
          by `callWith`) and a return type of any (like the parameters,
          as determined by `f` rather than `callWith`)

    `list`

    : 2\. A list of the arguments to pass to `f`.

    # Type

    ```
    callWith :: Args -> [Arg] -> a

    Args :: (Arg -> Any) | (Arg -> Args)

    Arg :: Any
    ```
  */
  callWith = f: builtins.foldl' lib.id f;

  /**
    Pass `x` to `f` and apply logical negation to the result.

    # Type

    ```
    not :: (Any -> bool) -> (Any -> bool)
    ```
  */
  not = f: x: !f x;
  notAttrs    = trivial'.not builtins.isAttrs;
  notBool     = trivial'.not builtins.isBool;
  notFloat    = trivial'.not builtins.isFloat;
  notFunction = trivial'.not builtins.isFunction;
  notInt      = trivial'.not builtins.isInt;
  notList     = trivial'.not builtins.isList;
  notNull     = trivial'.not builtins.isNull;
  notPath     = trivial'.not builtins.isPath;

  ifElse = cond: a: b: if cond then a else b;

  getType = value:
    if    lib.isAttrs value && lib.isStringLike value
    then  "stringCoercibleSet"
    else  builtins.typeOf value;

  # composeFunctions = f: lib'.lists.splitFor (builtins.foldl' f);
  #
  # composeFunctions' = fns: trivial'.composeFunctions 1 fns;

  isImportable = x:
    (lib.strings.isStringLike x)
    && (
      let p = /. + (toString x); in
      (builtins.pathExists p)
      && (
            (pathIsRegularFile p && lib.hasSuffix ".nix" p)
        ||  (pathIsDirectory p && builtins.pathExists (p + "/default.nix"))
      )
    );

  updateAttrsWith = attrs: update: attrs // (update attrs);
}
