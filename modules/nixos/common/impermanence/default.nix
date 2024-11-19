{
  config,
  inputs,
  lib,
  ...
}: let
  inherit (lib) mkOption types;
in {
  options.modulo.impermanence = {
    persistentDirectory = mkOption {
      type = types.str;
      description = ''
        Directory that will be used to store persistent files.
      '';
    };
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

    system.etc.overlay = {
      enable = true;
      mutable = true;
    };
  };
}
