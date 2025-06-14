{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    listToAttrs
    mkIf
    mkOption
    nameValuePair
    types
    ;

  cfg = config.modulo.desktop.portal;

  presets = {
    wlr = {
      package = pkgs.xdg-desktop-portal-wlr;
      service = "xdg-desktop-portal-wlr.service";

      handlers = [
        "org.freedesktop.impl.portal.Screenshot"
        "org.freedesktop.impl.portal.ScreenCast"
      ];
    };
  };
in
{
  options.modulo.desktop.portal = {
    flavor = mkOption {
      type = types.enum [ "wlr" ];
      description = ''
        XDG Desktop portal configuration preset.
      '';
    };
  };

  config = mkIf config.modulo.desktop.enable {
    xdg.portal = {
      enable = true;
      xdgOpenUsePortal = true;

      config.common = {
        default = [ "gtk" ];
      } // (listToAttrs (map (h: nameValuePair h [ cfg.flavor ]) presets.${cfg.flavor}.handlers));

      extraPortals = [
        pkgs.xdg-desktop-portal-gtk
        presets.${cfg.flavor}.package
      ];
    };

    modulo.desktop.systemd.forceSessionSlice = [
      "xdg-desktop-portal-gtk.service"
      presets.${cfg.flavor}.service
    ];

    # Override the default implementation of the xdg-document-portal.service
    # to fix missing /run/user/.../doc directories in sandboxed applications.
    #
    # Applications sandboxed with Bubblewrap rely on document portal directories
    # already existing at the time of their startup, but since the service activation
    # by default occurs only after initial D-Bus calls, Bubblewrap simply does not
    # propagate the newly mounted directory into the sandbox.
    #
    # To avoid that, xdg-document-portal is eagerly started during the initial
    # session launch.
    systemd.user.services.xdg-document-portal = {
      Unit = {
        Description = "Document portal";
        PartOf = [ "graphical-session.target" ];
      };

      Service = {
        ExecStart = "${pkgs.xdg-desktop-portal}/libexec/xdg-document-portal";
        Slice = "session.slice";
      };

      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
