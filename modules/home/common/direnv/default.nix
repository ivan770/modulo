{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.modulo.direnv;
in
{
  options.modulo.direnv = {
    enable = mkEnableOption "direnv support";
  };

  config = mkIf cfg.enable {
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    modulo.home-impermanence.directories = [
      ".local/share/direnv"
    ];
  };
}
