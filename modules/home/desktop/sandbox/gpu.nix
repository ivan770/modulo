{
  config,
  lib,
  sloth,
  ...
}: let
  inherit (lib) mkEnableOption mkIf mkOption types;

  cfg = config.modulo.gpu;
in {
  options.modulo.gpu = {
    enable = mkEnableOption "GPU propagation";

    driverPackage = mkOption {
      type = types.package;
      description = ''
        Propagated GPU package.
      '';
    };
  };

  config = mkIf cfg.enable {
    gpu.enable = true;

    bubblewrap = {
      bind.rw = [
        (sloth.concat' sloth.xdgCacheHome "/mesa_shader_cache")
        (sloth.concat' sloth.xdgCacheHome "/mesa_shader_cache_db")
      ];

      extraStorePaths = [cfg.driverPackage];
    };
  };
}
