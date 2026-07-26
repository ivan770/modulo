{
  lib,
  osConfig,
  ...
}:
let
  gnomeEnabled = osConfig.modulo.desktop.gnome.enable;
in
{
  config = lib.mkIf gnomeEnabled {
    modulo.home-impermanence = {
      directories = [
        # GNOME Keyring data
        {
          directory = ".local/share/keyrings";
          mode = "0700";
        }

        # GNOME Shell state
        {
          directory = ".local/share/gnome-shell";
          mode = "0700";
        }

        # App autostart config
        ".config/autostart"

        # Custom user backgrounds
        ".local/share/backgrounds"

        # Online accounts data
        ".config/goa-1.0"

        # GNOME settings daemon data
        ".local/share/gnome-settings-daemon"

        # GNOME software data
        ".local/share/gnome-software"
        ".local/state/gnome-software"

        # File explorer data
        ".config/nautilus"
        ".local/share/nautilus"

        # Display colour profiles
        ".local/share/icc"
      ];

      files = [
        # Initial setup flag
        ".config/gnome-initial-setup-done"

        # Scheme handler configuration
        ".config/mimeapps.list"

        # Display layout configuration
        {
          file = ".config/monitors.xml";
          method = "auto";
        }
      ];
    };
  };
}
