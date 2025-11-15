{
  config,
  lib,
  pkgs,
  sloth,
  ...
}:
let
  inherit (lib)
    listToAttrs
    mkEnableOption
    mkIf
    mkOption
    nameValuePair
    subtractLists
    types
    ;

  cfg = config.modulo.environment;

  vars = cfg.envPassthrough ++ [
    "_JAVA_AWT_WM_NONREPARENTING"
    "DBUS_SESSION_BUS_ADDRESS"
    "GTK_A11Y"
    "NIXOS_OZONE_WL"
    "NIXOS_XDG_OPEN_USE_PORTAL"
    "QT_QPA_PLATFORM"
    "QT_WAYLAND_DISABLE_WINDOWDECORATION"
    "SDL_VIDEODRIVER"
    "WAYLAND_DISPLAY"
    "XDG_RUNTIME_DIR"
  ];

  allowedVars = subtractLists cfg.envExclude vars;
  envPassthrough = listToAttrs (map (v: nameValuePair v (sloth.env' v)) allowedVars);
in
{
  options.modulo.environment = {
    enable = mkEnableOption "environment sandboxing" // {
      default = true;
    };

    envPassthrough = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = ''
        Environment variables to pass to the sandbox as-is.
      '';
    };

    envExclude = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = ''
        Environment variables to exclude from passthrough.
      '';
    };
  };

  config =
    let
      passwd = pkgs.writeText "sandbox-passwd" ''
        user:x:1000:100::/home/user:${lib.getExe' pkgs.shadow "nologin"}
      '';

      group = pkgs.writeText "sandbox-group" ''
        users:x:100:
      '';
    in
    mkIf cfg.enable {
      bubblewrap = {
        hostname = "computer";

        clearEnv = true;
        env = envPassthrough // {
          HOME = "/home/user";
          USER = "user";
        };

        bind.ro = [
          [
            (builtins.toString passwd)
            "/etc/passwd"
          ]
          [
            (builtins.toString group)
            "/etc/group"
          ]
        ];

        extraStorePaths = [
          passwd
          group
        ];
      };
    };
}
