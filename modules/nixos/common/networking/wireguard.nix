{
  config,
  lib,
  ...
}: let
  inherit
    (lib)
    filterAttrs
    hasAttr
    mapAttrsToList
    mkOption
    mkIf
    pipe
    types
    ;

  cfg = config.modulo.networking.wireguard;
in {
  options.modulo.networking.wireguard = {
    mesh = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          publicKey = mkOption {
            type = types.str;
            description = ''
              WireGuard node public key value.
            '';
          };

          address = mkOption {
            type = types.str;
            description = ''
              WireGuard node address.
            '';
          };

          endpoint = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = ''
              WireGuard node endpoint.
            '';
          };
        };
      });
      default = {};
      description = ''
        WireGuard mesh configuration.
      '';
    };
  };

  config = let
    hostname = config.networking.hostName;
  in
    mkIf (config.modulo.networking.enable && cfg.mesh != {}) {
      assertions = [
        {
          assertion = hasAttr hostname cfg.mesh;
          message = ''
            ${hostname} has to be a mesh member to activate WireGuard.
          '';
        }
      ];

      systemd.network.netdevs.wg0 = {
        netdevConfig = {
          Name = "wg0";
          Kind = "wireguard";
        };

        wireguardConfig = {
          PrivateKeyFile = config.modulo.secrets.values."wireguard/${hostname}";
          ListenPort = 51820;
        };

        wireguardPeers = pipe cfg.mesh [
          (filterAttrs (name: _: name != hostname))
          (mapAttrsToList (_: opts: {
            wireguardPeerConfig = {
              PublicKey = opts.publicKey;
              Endpoint = mkIf (opts.endpoint != null) "${opts.endpoint}:51820";
              AllowedIPs = ["${opts.address}/32"];
              PersistentKeepalive = 25;
            };
          }))
        ];
      };

      modulo = {
        # FIXME: Add IPv6 support
        networking.interfaces.wg0 = {
          dhcp = null;
          address = ["${cfg.mesh.${hostname}.address}/16"];
          onlineStatus = null;
          extraConfig.networkConfig.IPMasquerade = "ipv4";
        };

        secrets.applications."wireguard/${hostname}" = {
          inherit (config.users.users.systemd-network) group;

          owner = config.users.users.systemd-network.name;
        };
      };
    };
}
