{
  config,
  lib,
  sloth,
  ...
}: let
  inherit (lib) mkEnableOption mkIf mkOption types;

  cfg = config.modulo.fonts;
in {
  options.modulo.fonts = {
    enable =
      mkEnableOption "font propagation"
      // {
        default = true;
      };

    fonts = mkOption {
      type = types.listOf types.package;
      description = ''
        Propagated font list.
      '';
    };
  };

  config = mkIf cfg.enable {
    fonts = {
      inherit (cfg) fonts;

      enable = true;
    };

    bubblewrap.bind.ro = [(sloth.concat' sloth.xdgConfigHome "/fontconfig")];
  };
}
