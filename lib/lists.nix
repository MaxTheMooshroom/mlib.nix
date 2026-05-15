{ lib, lib', ... }:
let
  lists' = lib'.lists;

  inherit (builtins)
    foldl'
    genList
    head
    tail
    ;

  inherit (lib.lists)
    imap0
    imap1
    ;

  inherit (lib'.trivial)
    const
    turn
    ;
in
{
  splitFor = f: l: f (head l) (tail l);

  /**
    Create a list consisting of `n` copies of `elem`.

    # Arguments

    `elem`
    : 1\. The item to replicate.

    `n`
    : 2\. The number of times to replicate `elem`.

    # Type

    ```
    replicate' :: a -> Integer -> [a]
    ```
  */
  replicate' = turn genList const;

  sum = foldl' lib.add 0;

  enumerated0 = imap0 (idx: value: { inherit idx value; });
  enumerated1 = imap1 (idx: value: { inherit idx value; });

  ifoldl'0 = f: acc: list:
    foldl'
      (acc: { idx, value }: f idx acc value)
      acc
      (lists'.enumerated0 list);

  ifoldl'1 = f: acc: list:
    foldl'
      (acc: { idx, value }: f idx acc value)
      acc
      (lists'.enumerated1 list);
}
