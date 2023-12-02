{
  config,
  lib,
  ...
}: let
  inherit (lib) mkOption types;

  cfg = config.modulo.logging;
in {
  options.modulo.logging = {
    level = mkOption {
      type = types.enum [
        "emerg"
        "alert"
        "crit"
        "err"
        "warning"
        "notice"
        "info"
        "debug"
      ];
      default = "debug";
      description = ''
        Log level for messages to be stored in journal.
      '';
    };

    flavor = mkOption {
      type = types.enum ["volatile" "persistent"];
      default = "volatile";
      description = ''
        Preferred log storage.
      '';
    };

    maxLogSize = {
      volatile = mkOption {
        type = types.int;
        default = 128;
        description = ''
          Upper size limit enforced on journald's in-memory journal.
        '';
      };

      persistent = mkOption {
        type = types.int;
        default = 2048;
        description = ''
          Upper size limit enforced on journald's persistent journal.
        '';
      };
    };
  };

  config.services.journald.extraConfig = ''
    MaxLevelStore=${cfg.level}

    Storage=${cfg.flavor}

    RuntimeMaxUse=${toString cfg.maxLogSize.volatile}M
    SystemMaxUse=${toString cfg.maxLogSize.persistent}M
  '';
}
