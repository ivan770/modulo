{
  config,
  lib,
  ...
}: let
  inherit (lib) mkOption mkIf types;

  cfg = config.modulo.networking.dns;
in {
  options.modulo.networking.dns = {
    authentication = mkOption {
      type = types.enum ["required" "allowed" "forbidden"];
      default = "allowed";
      description = ''
        System-wide DNSSEC preference.
      '';
    };

    encryption = mkOption {
      type = types.enum ["required" "allowed"];
      default = "allowed";
      description = ''
        System-wide DNS-over-TLS preference.
      '';
    };
  };

  config = mkIf config.modulo.networking.enable {
    services.resolved = {
      enable = true;
      dnssec =
        if cfg.authentication == "required"
        then "true"
        else if cfg.authentication == "allowed"
        then "allow-downgrade"
        else "false";
      dnsovertls =
        if cfg.encryption == "required"
        then "true"
        else "opportunistic";
      llmnr = "false";
      extraConfig = ''
        MulticastDNS=false
      '';
    };

    networking.resolvconf.enable = false;
  };
}
