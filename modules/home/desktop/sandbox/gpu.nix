{
  config,
  lib,
  sloth,
  ...
}: let
  inherit
    (lib)
    mkEnableOption
    mkIf
    mkOption
    optional
    types
    ;

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

    driverPackage32Bit = mkOption {
      type = types.nullOr types.package;
      default = null;
      description = ''
        Propagated 32-bit GPU package.
      '';
    };
  };

  config = mkIf cfg.enable {
    gpu.enable = true;

    bubblewrap = {
      bind = {
        rw = [
          (sloth.concat' sloth.xdgCacheHome "/mesa_shader_cache")
          (sloth.concat' sloth.xdgCacheHome "/mesa_shader_cache_db")
        ];

        ro = mkIf (cfg.driverPackage32Bit != null) [
          "/run/opengl-driver-32"
        ];
      };

      extraStorePaths =
        [cfg.driverPackage]
        ++ optional (cfg.driverPackage32Bit != null) cfg.driverPackage32Bit;
    };
  };
}
