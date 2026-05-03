{ lib, lib' }:
let
  lists' = lib'.lists;

  inherit (builtins)
    foldl'
    genList
    head
    tail
    ;

  inherit (lib)
    id
    ;

  inherit (lib.lists)
    imap0
    imap1
    ;
in
{
  splitFor = f: l: f (head l) (tail l);

  /**
    Create a list consisting of `n` copies of `elem`.

    # Type

    ```
    replicate' :: a -> Integer -> [a]
    ```
  */
  replicate' = elem: genList (id elem);

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
