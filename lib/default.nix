{
  lib,
  ...
}:
let
  inherit (lib) foldr recursiveUpdate;
in
{
  recursiveMerge = foldr recursiveUpdate { };
}
