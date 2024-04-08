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

  config.nix = {
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
    };

    gc = mkIf cfg.autoGc {
      automatic = true;
      dates = "weekly";
    };
  };
}
