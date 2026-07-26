{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.modulo.desktop.gnome;

  defaultExtensions = [
    pkgs.gnomeExtensions.dash-to-dock
    pkgs.gnomeExtensions.appindicator
  ];
in
{
  options.modulo.desktop.gnome = {
    enable = mkEnableOption "GNOME desktop support";
  };

  config = mkIf cfg.enable {
    services.desktopManager.gnome = {
      enable = true;
      debug = true;
    };

    # GDM is required in this config.
    services.displayManager = {
      gdm.enable = true;
      defaultSession = "gnome";
    };

    environment = {
      systemPackages = defaultExtensions;

      # Some of these packages are entirely optional and can be installed with Flatpak.
      gnome.excludePackages = [
        pkgs.baobab
        pkgs.decibels
        pkgs.gnome-contacts
        pkgs.gnome-font-viewer
        pkgs.gnome-maps
        pkgs.gnome-music
        pkgs.gnome-tecla
        pkgs.gnome-connections
      ];
    };

    programs.dconf.profiles.user.databases = [
      {
        settings = {
          "org/gnome/shell".enabled-extensions = map (e: e.extensionUuid) defaultExtensions;
        };
      }
    ];

    modulo.impermanence = {
      directories =
        let
          mkDirectory = directory: {
            inherit directory;
            mode = "0700";
          };
        in
        [
          (mkDirectory "/var/lib/AccountsService")
          (mkDirectory "/var/lib/boltd")
          (mkDirectory "/var/lib/colord")
          (mkDirectory "/var/lib/geoclue")
          (mkDirectory "/var/lib/gnome-remote-desktop")
          (mkDirectory "/var/lib/usbguard")
        ];
    };
  };
}
