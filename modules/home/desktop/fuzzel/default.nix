{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    getExe
    hasAttrByPath
    mkEnableOption
    mkIf
    mkOption
    optionalString
    types
    ;

  cfg = config.modulo.desktop.fuzzel;
in
{
  options.modulo.desktop.fuzzel = {
    enable = mkEnableOption "fuzzel menu support";

    settings = mkOption {
      type = types.attrs;
      default = { };
      description = ''
        Fuzzel user-specific configuration.
      '';
    };
  };

  config = mkIf cfg.enable {
    programs.fuzzel = {
      inherit (cfg) settings;

      enable = true;
    };

    modulo.desktop.menu =
      let
        inherit (config.modulo.desktop.systemd) runner;

        bin = getExe config.programs.fuzzel.package;
        terminal = config.modulo.desktop.terminal.exec;

        promptFlag = optionalString (hasAttrByPath [
          "main"
          "prompt"
        ] cfg.settings) " -p \"${cfg.settings.main.prompt}\"";
      in
      {
        # INI configuration file doesn't preserve the trailing space
        # in prompt strings correctly, so we pass it as a flag here.
        application = ''${bin} --launch-prefix="${runner} " -T "${terminal}"${promptFlag}'';
        generic = prompt: ''${bin} -d -p "${prompt} "'';
      };
  };
}
