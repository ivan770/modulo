{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    concatStringsSep
    genAttrs
    getExe'
    listToAttrs
    mkEnableOption
    nameValuePair
    mkIf
    mkOption
    recursiveUpdate
    stringLength
    substring
    toUpper
    types
    ;

  inherit (config.modulo.desktop) menu;

  cfg = config.modulo.desktop.dunst;

  urgencyLevels = [
    "low"
    "normal"
    "critical"
  ];
  defaultLevel = "normal";

  colors = [
    "background"
    "foreground"
    "highlight"
  ];

  capitalize =
    val:
    let
      first = substring 0 1 val;
      other = substring 1 (stringLength val) val;
    in
    toUpper first + other;
in
{
  options.modulo.desktop.dunst = {
    enable = mkEnableOption "dunst notification daemon";

    settings =
      let
        mkLevel =
          level:
          (genAttrs colors (
            color:
            mkOption {
              type = types.nullOr types.str;
              # Make sure that in case of any color modifications
              # the colors are applied even to unspecified levels
              default = if level == defaultLevel then null else cfg.settings.${defaultLevel}.${color};
              defaultText =
                if level == defaultLevel then "null" else "config.modulo.desktop.dunst.${defaultLevel}.${color}";
              description = ''
                ${capitalize color} color for the ${level} level of urgency.
              '';
            }
          ))
          // {
            sound = mkOption {
              type = with types; nullOr (either str path);
              default = null;
              description = ''
                Audio file to play on new notifications.
              '';
            };
          };
      in
      genAttrs urgencyLevels mkLevel;

    height = mkOption {
      type = types.ints.positive;
      default = 200;
      description = ''
        Notification window max height.
      '';
    };

    offset = {
      horizontal = mkOption {
        type = types.int;
        default = 10;
        description = ''
          Horizontal offset.
        '';
      };

      vertical = mkOption {
        type = types.int;
        default = 10;
        description = ''
          Vertical offset.
        '';
      };

      gap = mkOption {
        type = types.ints.unsigned;
        default = 10;
        description = ''
          Gap size between multiple notifications.
        '';
      };
    };

    extraConfig = mkOption {
      type = with types; attrsOf (attrsOf (either str (either bool (either int (listOf str)))));
      default = { };
      description = ''
        Extra configuration.
      '';
    };
  };

  config = mkIf cfg.enable {
    services.dunst = {
      enable = true;

      settings =
        let
          mkConfig =
            prefix: val:
            listToAttrs (map (level: nameValuePair "${prefix}_${level}" (val level)) urgencyLevels);

          colorConfig = mkConfig "urgency" (
            level:
            listToAttrs (
              map (
                color:
                nameValuePair color (mkIf (cfg.settings.${level}.${color} != null) cfg.settings.${level}.${color})
              ) colors
            )
          );

          soundConfig = mkConfig "sound" (
            level:
            mkIf (cfg.settings.${level}.sound != null) {
              msg_urgency = level;
              script = toString (
                pkgs.writeShellScript "${level}-notification" ''
                  ${getExe' pkgs.pipewire "pw-play"} ${cfg.settings.${level}.sound}
                ''
              );
            }
          );
        in
        recursiveUpdate (
          {
            global = {
              follow = "mouse";
              enable_posix_regex = true;
              dmenu = menu.generic "Action:";

              mouse_left_click = "do_action";
              mouse_middle_click = "none";
              mouse_right_click = "close_current";

              height = toString cfg.height;
              offset = concatStringsSep "x" (
                map toString [
                  cfg.offset.horizontal
                  cfg.offset.vertical
                ]
              );
              gap_size = cfg.offset.gap;

              frame_width = 0;
              progress_bar_frame_width = 0;
            };
          }
          // colorConfig
          // soundConfig
        ) cfg.extraConfig;
    };

    modulo.desktop.systemd.forceSessionSlice = [
      "dunst.service"
    ];
  };
}
