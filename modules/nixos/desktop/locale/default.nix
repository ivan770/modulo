{ config, lib, ... }: {
  config = lib.mkIf config.modulo.desktop.enable {
    i18n = {
      extraLocales = "all";
      imperativeLocale = true;
    };

    modulo.impermanence.files = [
      "/etc/locale.conf"
    ];
  };
}
