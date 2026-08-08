{
  lib,
  ...
}:
let
  inherit (lib) foldr mkCall recursiveUpdate;
in
{
  recursiveMerge = foldr recursiveUpdate { };

  mkCall =
    args: path: overrides:
    let
      f = import path;
    in
    f (
      (builtins.intersectAttrs (builtins.functionArgs f) (args // { call = mkCall args; })) // overrides
    );
}
