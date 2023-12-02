{
  config,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.modulo.networking.dns;
in {
  options.modulo.networking.dns = {
    private = mkEnableOption "custom private DNS support";
  };

  config = mkIf config.modulo.networking.enable {
    services.resolved = {
      enable = true;
      llmnr = "false";
      dnssec =
        # Fix for NextDNS DNSSEC validation.
        if cfg.private
        then "false"
        else "allow-downgrade";
      extraConfig = ''
        DNSOverTLS=${
          if cfg.private
          then "true"
          else "opportunistic"
        }
        MulticastDNS=false
      '';
    };

    networking.resolvconf.enable = false;
  };
}
