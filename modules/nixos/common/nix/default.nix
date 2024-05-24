{
  config,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.modulo.nix;
in {
  options.modulo.nix = {
    autoGc = mkEnableOption "automatic Nix garbage collection";
  };

  config = {
    nix = {
      generateNixPathFromInputs = true;
      generateRegistryFromInputs = true;
      linkInputs = true;

      settings = {
        auto-optimise-store = true;
        flake-registry = "";
        trusted-users = [
          "root"
          "@wheel"
        ];
        warn-dirty = false;
      };

      gc = mkIf cfg.autoGc {
        automatic = true;
        dates = "weekly";
      };
    };

    nixpkgs.flake = {
      # Already handled by flake-utils-plus
      setNixPath = false;
      setFlakeRegistry = false;
    };
  };
}
