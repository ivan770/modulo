{
  inputs,
  lib,
  ...
}: let
  inherit (lib) concatStrings foldr recursiveUpdate;

  consts = {
    light = "ffffff";
    dark = "000000";
  };

  mkColor = {
    config,
    prefix ? null,
    transparency ? null,
  }: name: let
    colorScheme = config.modulo.desktop.colors.theme;

    source =
      inputs.nix-colors.colorSchemes.${colorScheme}.palette.${name}
      or consts.${name};
  in
    concatStrings [
      (builtins.toString prefix)
      source
      (builtins.toString transparency)
    ];
in {
  inherit mkColor;

  recursiveMerge = foldr recursiveUpdate {};

  mkTransparentColor = {
    config,
    prefix ? null,
  }: name: transparency:
    (mkColor {
      inherit config prefix transparency;
    })
    name;
}
