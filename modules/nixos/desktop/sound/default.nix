{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.modulo.desktop.sound;
in
{
  options.modulo.desktop.sound = {
    enable = mkEnableOption "audio playback support";
  };

  config.services.pipewire = mkIf cfg.enable {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };
}
