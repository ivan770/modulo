{
  config,
  lib,
  ...
}:
let
  inherit (lib) mapAttrs mkOption types;

  cfg = config.modulo.impermanence;
in
{
  options.modulo.impermanence = {
    directories = mkOption {
      type = with types; listOf (either attrs str);
      default = [ ];
      description = ''
        Application-specific persistent directories.
      '';
    };

    files = mkOption {
      type = with types; listOf (either attrs str);
      default = [ ];
      description = ''
        Application-specific persistent files.
      '';
    };
  };

  config.environment.persistence.${cfg.persistentDirectory} = {
    hideMounts = true;

    directories = [
      "/var/lib/nixos"
      "/var/lib/systemd"
      "/var/log"
      {
        directory = "/var/tmp";
        mode = "0777";
      }
    ]
    ++ cfg.directories;

    files = [
      "/etc/machine-id"
    ]
    ++ cfg.files;

    users = mapAttrs (_: modules: modules.modulo.home-impermanence) config.home-manager.users;
  };
}
