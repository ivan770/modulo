{
  inputs,
  lib,
  pkgs,
  ...
}:
pkgs.runCommand "fmt-check" {} ''
  ${lib.getExe pkgs.alejandra} -c ${inputs.self} 2>&1
  touch $out
''
