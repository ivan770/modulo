{
  config,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkForce mkIf;

  cfg = config.modulo.desktop.postgresql;
in {
  options.modulo.desktop.postgresql = {
    enable = mkEnableOption "desktop PostgreSQL support";
  };

  config = mkIf cfg.enable {
    services.postgresql = {
      enable = true;
      enableTCPIP = true;

      # Trust loopback TCP/IP connections
      authentication = ''
        host all all 127.0.0.1/32 trust
      '';
    };

    # Explicitly disable auto-start since not every desktop session requires PostgreSQL.
    systemd.services.postgresql.wantedBy = mkForce [];

    modulo.impermanence.directories = [
      {
        inherit (config.users.users.postgres) group;

        directory = "/var/lib/postgresql";
        mode = "0750";
        user = config.users.users.postgres.name;
      }
    ];
  };
}
