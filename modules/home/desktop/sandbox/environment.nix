{
  config,
  lib,
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
    types
    ;

  cfg = config.modulo.environment;

  vars = cfg.envPassthrough ++ [
    "_JAVA_AWT_WM_NONREPARENTING"
    "DBUS_SESSION_BUS_ADDRESS"
    "DISPLAY"
    "GTK_A11Y"
    "NIXOS_OZONE_WL"
    "QT_QPA_PLATFORM"
    "QT_WAYLAND_DISABLE_WINDOWDECORATION"
    "SDL_VIDEODRIVER"
    "WAYLAND_DISPLAY"
    "XDG_RUNTIME_DIR"
  ];

  envPassthrough = listToAttrs (map (v: nameValuePair v (sloth.env' v)) vars);
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
  };

  config = mkIf cfg.enable {
    bubblewrap = {
      hostname = "computer";

      shareEnv = false;

      env = envPassthrough // {
        HOME = "/home/user";
        USER = "user";
      };
    };
  };
}
