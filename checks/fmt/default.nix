{
  inputs,
  lib,
  pkgs,
  ...
}:
pkgs.runCommand "fmt-check" { } ''
  ${lib.getExe pkgs.nixfmt-tree} --ci -C ${inputs.self} 2>&1
  touch $out
''
