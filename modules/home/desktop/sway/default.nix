{
  config,
  lib,
  options,
  ...
}:
let
  inherit (lib)
    concatStringsSep
    mkEnableOption
    mkIf
    mkOption
    recursiveUpdate
    types
    ;

  cfg = config.modulo.desktop.sway;
in
{
  options.modulo.desktop.sway = {
    enable = mkEnableOption "Sway WM support";

    config = mkOption {
      type = types.attrs;
      default = { };
      description = ''
        Sway user-specific settings.
      '';
    };

    extraConfig = mkOption {
      type = types.str;
      default = "";
      description = ''
        Extra Sway configuration.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = config.modulo.desktop.enable;
        message = ''
          You need to activate config.modulo.desktop.enable to use the Sway module.
        '';
      }
    ];

    wayland.windowManager.sway = {
      enable = true;

      config = recursiveUpdate {
        input."type:keyboard" = {
          xkb_layout = concatStringsSep "," config.modulo.desktop.layout.layout;
          xkb_options =
            let
              opts =
                config.modulo.desktop.layout.options
                # Desktops have VTs disabled by default, so Ctrl+Alt+F* keys are useless anyway.
                ++ [ "srvrkeys:none" ];
            in
            concatStringsSep "," opts;
        };

        output."*".bg = "${config.modulo.desktop.wallpaper.file} fill";

        seat."*".xcursor_theme = concatStringsSep " " [
          config.modulo.desktop.cursor.name
          (toString config.modulo.desktop.cursor.size)
        ];

        bars = [ ];

        bindkeysToCode = true;
      } cfg.config;

      extraConfigEarly = ''
        set $term ${config.modulo.desktop.terminal.wrapped}
        set $menu ${config.modulo.desktop.menu.application}
      '';

      extraConfig =
        cfg.extraConfig
        + ''
          bindswitch --locked --reload lid:on exec ${config.modulo.desktop.lock.suspend}
        '';

      wrapperFeatures.gtk = true;

      # xdg-desktop-portal-gtk has broken app associations by default
      # when the xdgOpenUsePortal option is activated.
      # See https://github.com/NixOS/nixpkgs/issues/189851 for more info.
      systemd.variables = options.wayland.windowManager.sway.systemd.variables.default ++ [ "PATH" ];

      # FIXME: Remove hm-session-vars.sh loading as soon
      # as a more correct way to load environment variables into Sway is
      # introduced into HM.
      extraSessionCommands = ''
        [ -f "${config.home.profileDirectory}/etc/profile.d/hm-session-vars.sh" ] && . "${config.home.profileDirectory}/etc/profile.d/hm-session-vars.sh"

        export SDL_VIDEODRIVER=wayland
        export QT_QPA_PLATFORM=wayland
        export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
        export NIXOS_OZONE_WL=1
        export _JAVA_AWT_WM_NONREPARENTING=1
      '';
    };

    modulo.desktop.portal.flavor = "wlr";
  };
}
