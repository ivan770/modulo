{
  config,
  lib,
  sloth,
  ...
}: let
  inherit (lib) mkEnableOption mkIf mkMerge mkOption types;

  cfg = config.modulo.permissions;
in {
  options.modulo.permissions = {
    dconf = mkEnableOption "dconf access";
    document = mkEnableOption "Document Portal propagation";
    notifications = mkEnableOption "desktop notifications";

    mpris = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Unique MPRIS bus name.
        When `null`, MPRIS access is disabled.
      '';
    };
  };

  config = {
    bubblewrap.bind.rw = mkIf cfg.document [
      (sloth.concat' sloth.runtimeDir "/doc")
    ];

    dbus = {
      policies = mkMerge [
        {
          "org.freedesktop.DBus" = "talk";
          "org.freedesktop.portal.Desktop" = "talk";
          "org.freedesktop.portal.Flatpak" = "talk";
        }

        (mkIf cfg.dconf {
          "ca.desrt.dconf" = "talk";
        })

        (mkIf cfg.document {
          "org.freedesktop.portal.Documents" = "talk";
        })

        (mkIf cfg.notifications {
          "org.freedesktop.Notifications" = "talk";
          "org.freedesktop.portal.Notification" = "talk";
        })

        (mkIf (cfg.mpris != null) {
          "org.mpris.MediaPlayer2.Player" = "talk";
          "org.mpris.MediaPlayer2.${cfg.mpris}" = "own";
          "org.mpris.MediaPlayer2.${cfg.mpris}.*" = "own";
        })
      ];

      rules = {
        call."org.freedesktop.portal.*" = ["*"];
        broadcast."org.freedesktop.portal.*" = ["@/org/freedesktop/portal/*"];
      };
    };
  };
}
