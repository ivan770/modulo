{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) getExe mkEnableOption mkIf;

  cfg = config.modulo.desktop.backlight;
in {
  options.modulo.desktop.backlight = {
    enable = mkEnableOption "display backlight support";
  };

  config = mkIf cfg.enable {
    programs.light.enable = true;

    services.acpid = {
      enable = true;

      handlers = let
        light = getExe pkgs.light;
      in {
        brightnessUp = {
          event = "video/brightnessup";
          action = "${light} -A 5";
        };

        brightnessDown = {
          event = "video/brightnessdown";
          action = "${light} -U 5";
        };
      };
    };
  };
}
