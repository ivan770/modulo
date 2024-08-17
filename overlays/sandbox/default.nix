{
  inputs,
  lib,
  ...
}: _: pkgs: {
  mkNixPak = inputs.nixpak.lib.nixpak {
    inherit lib pkgs;
  };
}
