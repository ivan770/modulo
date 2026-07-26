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

        # GNOME settings daemon data
        ".local/share/gnome-settings-daemon"

        # Display colour profiles
        ".local/share/icc"
      ];

      files = [
        # Initial setup flag
        ".config/gnome-initial-setup-done"

        # Display layout configuration
        {
          file = ".config/monitors.xml";
          method = "auto";
        }
      ];
    };
  };
}
