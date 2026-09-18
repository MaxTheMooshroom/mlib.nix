{ lib, lib', ... }:
let
  constraints' = lib'.constraints;
  strings' = lib'.strings;
  trivial' = lib'.trivial;

  inherit (lib.filesystem)
    pathIsDirectory
    pathIsRegularFile
    ;
in
{
  add = a: b: a + b;

  seq = trivial'.dup builtins.seq;
  break = trivial'.turn trivial'.seq break;
  hasAttr =
    trivial'.turn
      (constraints'.satisfiesBoth builtins.isAttrs)
      builtins.hasAttr
    ;

  #?  eq :: any -> any -> bool;
  eq = a: b: b == a;
  #?  neq :: any -> any -> bool;
  neq = a: b: a != b;

  #?  swap :: A -> (A -> B) -> B;
  swap = x: f: f x;
  #?  dup :: (A -> A -> B) -> A -> B;
  dup = f: x: f x x;

  #?  turn :: (B -> C) -> (A -> B) -> A -> C;
  turn =
    f: g: x:
    f (g x)
    ;

  #?  turn' :: (A -> B) -> (B -> C) -> A -> C;
  turn' = lib.flip trivial'.turn;

  #?  fanout :: (B -> C -> D) -> (A -> B) -> A -> D;
  fanout =
    f: g: x:
    (f x) (g x)
    ;

  #?  turn2 :: (C -> D) -> (A -> B -> C) -> A -> D;
  #~  turn2 = f: g: a: b: f (g a b);
  turn2 =
    let inherit (trivial') turn; in
    turn turn turn
    ;

  /** call a function with a list of parameters. */
  #?  callWith :: (A -> B -> ... -> N -> R) -> [A B ... N] -> R;
  #~  callWith = f: list: foldl' (f': x: f' x) f list;
  callWith = builtins.foldl' lib.id;

  negate = x: !x;

  #?  not :: (A -> (B :: bool)) -> A -> B;
  not = f: x: !f x;
  #?  notAttrs :: (maybe set) -> bool;
  notAttrs = trivial'.not builtins.isAttrs;
  #?  notBool :: (maybe bool) -> bool;
  notBool = trivial'.not builtins.isBool;
  #?  notFloat :: (maybe float) -> bool;
  notFloat = trivial'.not builtins.isFloat;
  #?  notFunction :: (maybe function) -> bool;
  notFunction = trivial'.not trivial'.isFunction;
  #?  notInt :: (maybe int) -> bool;
  notInt = trivial'.not builtins.isInt;
  #?  notList :: (maybe list) -> bool;
  notList = trivial'.not builtins.isList;
  #?  notNull :: (maybe null) -> bool;
  notNull = trivial'.not builtins.isNull;
  #?  notPath :: (maybe path) -> bool;
  notPath = trivial'.not builtins.isPath;
  #?  notDerivation :: (maybe derivation) -> bool;
  notDerivation = trivial'.not lib.isDerivation;

  #?  True :: any -> true;
  True = lib.const true;
  #?  False :: any -> false;
  False = lib.const false;
  #?  Null :: any -> null;
  Null = lib.const null;
  #?  EmptySet :: any -> {};
  EmptySet = lib.const { };

  #?  ifThenElse :: bool -> A -> B -> (A | B);
  ifThenElse =
    cond: a: b:
    if cond then a else b
    ;

  #?  ifPredThenElse :: (C -> bool) -> A -> B -> C -> (A | B);
  ifPredThenElse =
    trivial'.turn
      (trivial'.turn' (trivial'.turn lib.flip (lib.flip trivial'.ifThenElse)))
      (trivial'.turn trivial'.turn trivial'.turn')
    ;

  #?  mapValueUnless :: (A -> bool) -> (A -> B) -> A -> (A | B);
  #~  mapValueUnless =
  #~    predicate: operator: value:
  #~    ifThenElse
  #~      (predicate value)
  #~      value
  #~      (operator value)
  #~    ;
  mapValueUnless =
    trivial'.turn trivial'.fanout
      (trivial'.turn trivial'.dup (trivial'.turn trivial'.ifThenElse))
    ;

  #?  mapValueIf :: (A -> bool) -> (A -> B) -> A -> (A | B);
  #~  mapValueIf =
  #~    pred: operator: value:
  #~    ifThenElse
  #~      (pred value)
  #~      (operator value)
  #~      value
  #~    ;
  mapValueIf = trivial'.turn trivial'.mapValueUnless trivial'.not;

  #?  getType :: any -> string;
  #~  getType =
  #~    value:
  #~    if    lib.isAttrs value && lib.isStringLike value
  #~    then  "stringCoercibleSet"
  #~    else  builtins.typeOf value
  #~    ;
  getType =
    trivial'.dup
      (
        trivial'.turn
          (
            trivial'.ifPredThenElse
              (constraints'.satisfiesBoth lib.isAttrs lib.isStringLike)
              "stringCoercibleSet"
          )
          builtins.typeOf
      )
    ;

  /**
    Pipe a value through a list of functions, where the result of each
    function is the argument to the next function in the list.
  */
  #? pipe :: Any -> [(Any -> Any)] -> Any
  pipe = builtins.foldl' trivial'.swap;

  min0 = lib.max 0;
  max0 = lib.min 0;
  thresholdMax = N: x: trivial'.ifThenElse (N <= x) 0 x;
  clamp = lib.flip (trivial'.turn trivial'.turn2 lib.max) lib.min;

  getLevenshteinFast = trivial'.turn builtins.filter strings'.levenshteinFast;

  #?  isImportable :: (maybe importable) -> bool;
  isImportable =
    constraints'.satisfiesBoth
      lib.strings.isStringLike
      (
        trivial'.turn
          (
            constraints'.satisfiesAll
              [
                builtins.pathExists
                (
                  constraints'.satisfiesEither
                    (
                      constraints'.satisfiesBoth
                        pathIsRegularFile
                        (lib.hasSuffix ".nix")
                    )
                    (
                      constraints'.satisfiesBoth
                        pathIsDirectory
                        (builtins.pathExists (lib.flip trivial'.add "/default.nix"))
                    )
                )
              ]
          )
          (trivial'.turn (trivial'.add /.) toString)
      )
    ;

  updateAttrsWith = attrs: update: attrs // (update attrs);

  #? isOrMakeUsing :: ((A :: maybe T) -> bool) -> (A -> T) -> A -> T;
  isOrMakeUsing =
    let
      throwUnlessPred =
        lib.flip
          lib'.asserts.throwUnlessPred
          "arg 2 passed to 'isOrMakeUsing' did not produce a value from arg 3 that passes the provided predicate (arg 1)"
        ;

      turnturn = trivial'.turn trivial'.turn;
    in
    trivial'.fanout
      (turnturn trivial'.mapValueUnless)
      (turnturn throwUnlessPred)
    ;

  isFunction =
    lib'.constraints.satisfiesEither
      builtins.isFunction
      trivial'.isFunctor
    ;

  toFunction = trivial'.isOrMakeUsing builtins.isFunction lib.const;

  functionArgs =
    trivial'.turn
      (trivial'.mapValueIf builtins.isFunction builtins.functionArgs)
      (
        trivial'.mapValueIf
          (
            constraints'.satisfiesBoth
              trivial'.isFunctor
              (builtins.hasAttr "__functionArgs")
          )
          (builtins.getAttr "__functionArgs")
      )
    ;

  #?  toFunctor ::
  #?    (one-of [(functorTo R) (functionTo R) (R :: any)]) ->
  #?      (functorTo R)
  #?    ;
  #?
  #?  functorTo ::
  #?    (R :: any) ->
  #?      (
  #?        Self =
  #?          {
  #?            __functionArgs? :: (attrsOf bool),
  #?            __functor :: Self -> any -> R,
  #?          }
  #?      )
  #?    ;
  toFunctor =
    let
      attrs-base =
        { __functionArgs = lib.functionArgs; __functor = lib.const; }
        ;
    in
      trivial'.isOrMakeUsing
        trivial'.isFunctor
        (
          trivial'.turn
            #? :: (any -> (T :: any)) -> (functorTo T);
            (lib.flip trivial'.applyAttrs attrs-base)
            trivial'.toFunction
        )
    ;

  #? applyAttrs :: A -> (attrsOf@[T] (A -> T)) -> (attrsOf T);
  #~ applyAttrs = value: attrs: mapAttrs (_: v: v x) attrs;
  applyAttrs =
    trivial'.turn
      builtins.mapAttrs
      (
        trivial'.turn
          lib.const
          trivial'.swap
      )
    ;

  isFunctor =
    with builtins;
    let
      getFunctor = getAttr "__functor";
      turn-isFunction = trivial'.turn builtins.isFunction;
    in
    lib'.constraints.satisfiesAll
      [
        isAttrs
        (hasAttr "__functor")
        (turn-isFunction getFunctor)
        (turn-isFunction (trivial'.dup getFunctor))
      ]
      ;
}
