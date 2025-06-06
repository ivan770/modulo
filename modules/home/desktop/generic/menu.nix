{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkOption types;

  cfg = config.modulo.desktop.menu;
in
{
  options.modulo.desktop.menu = {
    generic = mkOption {
      type = types.functionTo types.str;
      description = ''
        Generic menu launcher that accepts a prompt string value.
      '';
    };

    application = mkOption {
      type = types.str;
      description = ''
        Application menu launcher.
      '';
    };
  };

  config.home.packages = mkIf config.modulo.desktop.enable [
    # Dynamic menu wrapper for scripting purposes
    (pkgs.writeShellScriptBin "runHmMenu" (cfg.generic "\"$@\""))
  ];
}
