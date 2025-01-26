{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}: let
  inherit (lib) mkOption types;
in {
  options.modulo.desktop.sandbox = {
    builder = mkOption {
      type = types.anything;
      internal = true;
      description = ''
        HM-specific NixPak builder.
      '';
    };
  };

  config.modulo.desktop.sandbox.builder = baseConfig:
    pkgs.mkNixPak {
      config = {
        lib,
        sloth,
        ...
      }: {
        imports = [
          baseConfig
          ./fonts.nix
          ./gpu.nix
          ./gtk.nix
          ./locale.nix
          ./permissions.nix
          ./syscallFilter.nix
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

            ro = [(sloth.concat' sloth.homeDir "/.XCompose")];
          };

          bindEntireStore = lib.mkDefault false;
        };

        modulo = {
          fonts.fonts = config.modulo.desktop.fonts.packages;
          gpu.driverPackage = osConfig.hardware.graphics.package;
          gtk.cursor = {
            inherit (config.modulo.desktop.cursor) package name size;
          };
        };
      };
    };
}
