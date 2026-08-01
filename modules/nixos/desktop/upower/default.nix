{ config, lib, ... }: {
  config = lib.mkIf config.modulo.desktop.enable {
    services.upower = {
      enable = true;
      noPollBatteries = lib.mkDefault true;
    };

    modulo.impermanence.directories = [
      {
        directory = "/var/lib/upower";
        mode = "0700";
      }
    ];
  };
}
