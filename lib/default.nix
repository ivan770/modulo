{lib, ...}: {
  recursiveMerge = lib.foldr lib.recursiveUpdate {};
}
