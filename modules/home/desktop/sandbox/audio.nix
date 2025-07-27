{
  config,
  lib,
  sloth,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.modulo.audio;
in
{
  options.modulo.audio = {
    enable = mkEnableOption "audio support";
  };

  config = mkIf cfg.enable {
    bubblewrap.bind.ro = [ (sloth.concat' sloth.runtimeDir "/pulse/native") ];
  };
}
