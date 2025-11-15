{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    concatStringsSep
    getExe
    getExe'
    mkDefault
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

        seat."*" = {
          shortcuts_inhibitor = "disable";

          xcursor_theme = concatStringsSep " " [
            config.modulo.desktop.cursor.name
            (toString config.modulo.desktop.cursor.size)
          ];
        };

        bars = [ ];

        bindkeysToCode = true;
      } cfg.config;

      extraConfigEarly = ''
        set $term ${config.modulo.desktop.terminal.wrapped}
        set $menu ${config.modulo.desktop.menu.application}
      '';

      extraConfig =
        let
          variables = concatStringsSep " " config.wayland.windowManager.sway.systemd.variables;

          postStart = [
            "${getExe' pkgs.systemdMinimal "systemctl"} --user import-environment ${variables}"
            "${getExe' pkgs.systemdMinimal "systemd-notify"} --ready"
          ];
        in
        cfg.extraConfig
        + ''
          exec_always "${concatStringsSep ";" postStart}"
        '';

      wrapperFeatures.gtk = true;

      # systemd integration is implemented separately
      systemd.enable = false;
    };

    modulo.desktop = {
      portal.flavor = "wlr";

      systemd = {
        startCommand = getExe config.wayland.windowManager.sway.package;
        reloadCommand = "${getExe' config.wayland.windowManager.sway.package "swaymsg"} reload";
      };

      wlogout.enable = mkDefault true;
    };
  };
}
