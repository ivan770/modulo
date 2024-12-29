{
  config,
  lib,
  sloth,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.modulo.portal;
in {
  options.modulo.portal = {
    document = mkEnableOption "Document Portal propagation";
  };

  config.bubblewrap.bind.rw = mkIf cfg.document [
    (sloth.concat' sloth.runtimeDir "/doc")
  ];
}
