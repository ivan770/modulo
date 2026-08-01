{
  config,
  lib,
  ...
}:
{
  config.services.pipewire = lib.mkIf config.modulo.desktop.enable {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };
}
