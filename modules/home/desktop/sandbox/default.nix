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
          sloth,
          ...
        }:
        {
          imports = [
            baseConfig
            ./audio.nix
            ./environment.nix
            ./fonts.nix
            ./gpu.nix
            ./gtk.nix
            ./locale.nix
            ./permissions.nix
            ./syscallFilter.nix
            ./x11.nix
          ];

          etc.sslCertificates.enable = lib.mkDefault true;

          bubblewrap = {
            bind = {
              rw = [
                [
                  (sloth.mkdir (sloth.concat' sloth.appDir "/tmp"))
                  "/tmp"
                ]
              ];

              ro = [
                [
                  (sloth.concat' sloth.homeDir' "/.XCompose")
                  (sloth.concat' sloth.homeDir "/.XCompose")
                ]
              ];
            };

            bindEntireStore = lib.mkDefault false;
          };

          modulo = {
            fonts.fonts = config.modulo.desktop.fonts.packages;

            gpu = {
              driverPackage = graphics.package;
              driverPackage32Bit = mkIf graphics.enable32Bit graphics.package32;
            };

            gtk =
              let
                gtkEnabled = mkIf config.gtk.enable;
              in
              {
                gtk3Config = gtkEnabled config.xdg.configFile."gtk-3.0/settings.ini".text;
                gtk4Config = gtkEnabled config.xdg.configFile."gtk-4.0/settings.ini".text;

                cursor = {
                  inherit (config.modulo.desktop.cursor) package name size;
                };
              };
          };
        };
    };
}
