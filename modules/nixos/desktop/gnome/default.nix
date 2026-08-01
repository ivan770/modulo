{
  config,
  lib,
  pkgs,
  ...
}:
let
  defaultExtensions = [
    pkgs.gnomeExtensions.dash-to-dock
    pkgs.gnomeExtensions.appindicator
  ];
in
{
  config = lib.mkIf config.modulo.desktop.enable {
    services = {
      desktopManager.gnome.enable = true;
      displayManager.gdm.enable = true;
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
