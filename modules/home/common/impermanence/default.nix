{lib, ...}: let
  inherit (lib) mkOption types;
in {
  options.modulo.home-impermanence = {
    directories = mkOption {
      # Let impermanence module handle the typeck
      type = with types; listOf (either attrs str);
      default = [];
      description = ''
        Personal user directories to persist.
      '';
    };

    files = mkOption {
      type = with types; listOf (either attrs str);
      default = [];
      description = ''
        Personal user files to persist.
      '';
    };
  };

  config = {
    modulo.home-impermanence = {
      directories = [
        # .cache
        {
          directory = ".cache/dconf";
          mode = "0700";
        }
        ".cache/fontconfig"
        ".cache/mesa_shader_cache"
        ".cache/nix"

        # .*
        ".cargo"
        {
          directory = ".pki";
          mode = "0700";
        }
        ".rustup"

        # .config/*
        {
          directory = ".config/dconf";
          mode = "0700";
        }

        # .local/*
        {
          directory = ".local/state/wireplumber";
          mode = "0700";
        }

        # Personal directories
        "Config"
        "Documents"
        "Downloads"
        "Music"
        "Pictures"
        "Public"
        "Templates"
        "Videos"
      ];

      files = [
        {
          file = ".ssh/known_hosts";
          parentDirectory = {mode = "0700";};
        }
        ".ssh/id_rsa"
      ];
    };
  };
}
