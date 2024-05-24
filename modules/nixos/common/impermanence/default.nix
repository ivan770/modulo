{
  config,
  inputs,
  lib,
  ...
}: let
  inherit (lib) isString mapAttrs mkEnableOption mkIf mkOption types;

  cfg = config.modulo.impermanence;
in {
  options.modulo.impermanence = {
    persistentDirectory = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Directory that will be used to store persistent files.
      '';
    };

    directories = mkOption {
      type = with types; listOf (either attrs str);
      default = [];
      description = ''
        Application-specific persistent directories.
      '';
    };

    files = mkOption {
      type = with types; listOf (either attrs str);
      default = [];
      description = ''
        Application-specific persistent files.
      '';
    };

    useHomeManager = mkEnableOption "home-manager impermanence support";
  };

  imports = [
    inputs.impermanence.nixosModules.impermanence
  ];

  config = mkIf (isString cfg.persistentDirectory) {
    # sops-nix executes secretsForUsers before impermanence module activation,
    # leading to incorrect user password provision on startup.
    # To fix this behaviour, host keys can be simply moved to persistent directory explicitly.
    services.openssh.hostKeys = [
      {
        bits = 4096;
        path = "${cfg.persistentDirectory}/etc/ssh/ssh_host_rsa_key";
        type = "rsa";
      }
      {
        path = "${cfg.persistentDirectory}/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
    ];

    # FIXME: https://github.com/NixOS/nixpkgs/issues/311125
    # FIXME: https://github.com/NixOS/nixpkgs/issues/311665
    # system.etc.overlay = {
    #   enable = true;
    #   mutable = true;
    # };

    # Coredumps are unused in this configuration.
    systemd.coredump.extraConfig = ''
      Storage=none
    '';

    # FIXME: Enable systemd-sysusers?
    users.mutableUsers = false;

    environment.persistence.${cfg.persistentDirectory} = {
      hideMounts = true;

      directories =
        [
          "/var/lib/nixos"
          "/var/lib/systemd"
          "/var/log"
          {
            directory = "/var/tmp";
            mode = "0777";
          }
        ]
        ++ cfg.directories;

      files =
        [
          "/etc/machine-id"
        ]
        ++ cfg.files;

      users = mkIf cfg.useHomeManager (mapAttrs
        (_: modules: modules.modulo.home-impermanence)
        config.home-manager.users);
    };
  };
}
