{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    isList
    mapAttrs
    mkIf
    mkOption
    types
    ;

  cfg = config.modulo.headless.certificates;
in
{
  options.modulo.headless.certificates = {
    acme = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            email = mkOption {
              type = types.str;
              description = ''
                E-mail address used to authenticate with the ACME server.
              '';
            };

            dnsProvider = mkOption {
              type = types.str;
              description = ''
                DNS provider name for the Lego ACME client.
              '';
            };

            extraDomainNames = mkOption {
              type = types.nullOr (types.listOf types.str);
              default = null;
              description = ''
                Extra domains to provision the certificate for.
                `null` implies provisioning for a single-level wildcard subdomain.
              '';
            };
          };
        }
      );
      default = { };
      description = ''
        Certificates, that are automatically provisioned with ACME.
      '';
    };
  };

  config = mkIf (cfg.acme != { }) {
    security.acme = {
      acceptTerms = true;
      certs = mapAttrs (domain: options: {
        inherit (options) dnsProvider email;

        environmentFile = config.modulo.secrets.values.dnsCredentials;

        extraDomainNames =
          if isList options.extraDomainNames then options.extraDomainNames else [ "*.${domain}" ];
      }) cfg.acme;
    };

    modulo = {
      impermanence.directories = [
        {
          inherit (config.security.acme.defaults) group;

          directory = "/var/lib/acme";
          user = config.users.users.acme.name;
        }
      ];

      secrets.applications.dnsCredentials = {
        inherit (config.security.acme.defaults) group;

        owner = config.users.users.acme.name;
      };
    };
  };
}
