{
  inputs,
  lib,
  ...
}: _: pkgs: {
  mkNixPak = inputs.nixpak.lib.nixpak {
    inherit pkgs;
    inherit (pkgs) lib;
  };
}
