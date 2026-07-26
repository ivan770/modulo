{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkOption types;
  inherit (osConfig.hardware) graphics;
in
{
  options.modulo.desktop.sandbox = {
    builder = mkOption {
      type = types.anything;
      internal = true;
      description = ''
        HM-specific NixPak builder.
      '';
    };
  };

  config.modulo.desktop.sandbox.builder =
    baseConfig:
    pkgs.mkNixPak {
      config =
        {
          lib,
          ...
        }:
        {
          imports = [ baseConfig ] ++ (lib.fileset.toList (lib.fileset.fileFilter (f: f.hasExt "nix") ./.));

          modulo = {
            fonts.fonts = config.modulo.desktop.fonts.packages;

            gpu = {
              driverPackage = graphics.package;
              driverPackage32Bit = mkIf graphics.enable32Bit graphics.package32;
            };
          };
        };
    };
}
