{
  config,
  inputs,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkIf mkOption types;

  cfg = config.modulo.impermanence;
in {
  options.modulo.impermanence = {
    persistentDirectory = mkOption {
      type = types.str;
      description = ''
        Directory that will be used to store persistent files.
      '';
    };

    experimental = mkEnableOption "experimental impermanence options";
  };

  imports = [
    inputs.impermanence.nixosModules.impermanence

    ./files.nix
    ./hostkeys.nix
  ];

  config = {
    # Coredumps are unused in this configuration.
    systemd.coredump.extraConfig = ''
      Storage=none
    '';

    users.mutableUsers = false;

    # Nix can quickly drain the entire root tmpfs during the build process,
    # so the build directory has to be moved to a persistent storage.
    nix.settings.build-dir = "/var/tmp";

    system.etc.overlay = mkIf cfg.experimental {
      enable = true;
      mutable = true;
    };
  };
}
