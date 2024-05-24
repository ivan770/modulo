{
  inputs,
  lib,
  pkgs,
  ...
}:
pkgs.runCommand "statix" {} ''
  ${lib.getExe pkgs.statix} check ${inputs.self} 2>&1
  touch $out
''
