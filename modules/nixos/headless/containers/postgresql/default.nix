{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkOption types;

  cfg = config.modulo.headless.postgresql;
in {
  options.modulo.headless.postgresql = {
    apps = mkOption {
      type = with types; listOf str;
      default = [];
      description = ''
        Available database applications.
      '';
    };
  };

  config.modulo.headless.containers.configurations.postgresql = let
    package = pkgs.postgresql_16;
    dataDir = "/var/lib/postgresql";
  in {
    config = {
      exposedServices,
      settings ? {},
      ...
    }: {
      services.postgresql = {
        inherit package settings;

        enable = true;
        dataDir = "${dataDir}/${package.psqlSchema}";

        enableTCPIP = true;
        port = exposedServices.main;

        ensureUsers =
          map (name: {
            inherit name;

            ensureDBOwnership = true;
          })
          cfg.apps;

        ensureDatabases = cfg.apps;

        # Trust only cross-container communication
        authentication = ''
          host all all 192.168.100.0/24 trust
        '';
      };
    };

    bindSlots.data = dataDir;
    exposedServices = ["main"];
  };
}
