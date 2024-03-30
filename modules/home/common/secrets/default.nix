{lib, ...}: let
  inherit (lib) mkOption types;
in {
  options.modulo.secrets = {
    applications = mkOption {
      type = types.listOf types.str;
      default = [];
      description = ''
        User-specific application secrets.
      '';
    };

    values = mkOption {
      type = types.attrsOf types.str;
      readOnly = true;
      description = ''
        Paths to user-specific secrets.
      '';
    };
  };
}
