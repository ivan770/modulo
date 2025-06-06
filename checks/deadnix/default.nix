{
  inputs,
  lib,
  pkgs,
  ...
}:
pkgs.runCommand "deadnix" { } ''
  ${lib.getExe pkgs.deadnix} -f ${inputs.self} 2>&1
  touch $out
''
