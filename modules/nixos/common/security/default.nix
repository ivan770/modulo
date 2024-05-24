{lib, ...}: let
  inherit (lib) mkForce;
in {
  environment.defaultPackages = mkForce [];

  security = {
    doas = {
      enable = true;
      # Force override the default "wheel" group configuration.
      extraRules = mkForce [
        {
          groups = ["wheel"];
          keepEnv = true;
          # Fix missing git binary error when rebuilding the system configuration
          setEnv = ["PATH"];
        }
      ];
    };

    sudo.enable = false;
  };
}
