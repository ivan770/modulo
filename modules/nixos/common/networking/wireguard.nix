{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    all
    any
    attrValues
    filterAttrs
    flatten
    hasAttr
    listToAttrs
    mapAttrsToList
    mkOption
    mkIf
    nameValuePair
    pipe
    types
    ;

  cfg = config.modulo.networking.wireguard;
in
{
  options.modulo.networking.wireguard = {
    ulaCidr = mkOption {
      type = types.str;
      description = ''
        IPv6 ULA CIDR value used for routing intra-network traffic.
      '';
    };

    addToHosts = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether to add mesh members to /etc/hosts.
      '';
    };

    mesh = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            relay = {
              node = mkOption {
                type = types.str;
                description = ''
                  Name of the designated relay node within a region.
                '';
              };

              endpoint = mkOption {
                type = types.str;
                description = ''
                  WireGuard node endpoint.
                '';
              };

              subnet = mkOption {
                type = types.str;
                description = ''
                  IPv6 subnet handled by the relay.
                '';
              };
            };

            nodes = mkOption {
              type = types.attrsOf (
                types.submodule {
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
                  };
                }
              );
              default = { };
              description = ''
                Nodes that can connect to the region.
                A single node may belong to multiple regions.
              '';
            };
          };
        }
      );
      default = { };
      description = ''
        WireGuard mesh configuration.
      '';
    };

    addresses = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = ''
        Assigned WireGuard addresses.
      '';
    };

    actsAsRelay = mkOption {
      internal = true;
      type = types.bool;
      default = false;
      description = ''
        Whether the current host acts as a WireGuard relay.
      '';
    };
  };

  config =
    let
      hostname = config.networking.hostName;

      memberZones = filterAttrs (_: { nodes, ... }: hasAttr hostname nodes) cfg.mesh;
    in
    mkIf (config.modulo.networking.enable && cfg.mesh != { }) {
      assertions = [
        {
          assertion = all (
            {
              relay,
              nodes,
            }:
            hasAttr relay.node nodes
          ) (attrValues cfg.mesh);
          message = ''
            All configured relays should exist within the `nodes` attrset.
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

        wireguardPeers = pipe memberZones [
          (mapAttrsToList (
            zone:
            {
              relay,
              nodes,
            }:
            let
              attachedNodes = map (node: {
                PublicKey = node.publicKey;
                AllowedIPs = [ "${node.address}/128" ];
              }) (attrValues nodes);

              neighborRelays = pipe cfg.mesh [
                (filterAttrs (neighborZone: _: zone != neighborZone))
                (mapAttrsToList (
                  _:
                  {
                    relay,
                    nodes,
                  }:
                  {
                    PublicKey = nodes.${relay.node}.publicKey;
                    Endpoint = relay.endpoint;
                    AllowedIPs = [ "${relay.subnet}/64" ];
                    PersistentKeepalive = 25;
                  }
                ))
              ];

              subnetRelay = [
                {
                  PublicKey = nodes.${relay.node}.publicKey;
                  Endpoint = relay.endpoint;
                  AllowedIPs = [ "${cfg.ulaCidr}/48" ];
                  PersistentKeepalive = 25;
                }
              ];
            in
            if
              relay.node == hostname
            # Relay has to be aware about all nodes within its region
            # and about neighbor relays
            then
              attachedNodes ++ neighborRelays
            # Regular node has to be aware only about its relay
            else
              subnetRelay
          ))
          flatten
        ];
      };

      boot.kernel.sysctl."net.ipv6.conf.all.forwarding" = mkIf cfg.actsAsRelay true;

      networking.hosts = mkIf cfg.addToHosts (
        pipe cfg.mesh [
          (mapAttrsToList (
            _:
            { nodes, ... }:
            mapAttrsToList (node: { address, ... }: nameValuePair address [ "${node}.lan" ]) nodes
          ))
          flatten
          listToAttrs
        ]
      );

      modulo = {
        networking = {
          interfaces.wg0 = {
            dhcp = null;
            address = map (address: "${address}/48") cfg.addresses;
            onlineStatus = null;
          };

          wireguard = {
            actsAsRelay = any ({ relay, ... }: relay.node == hostname) (attrValues memberZones);

            addresses = mapAttrsToList (_: { nodes, ... }: nodes.${hostname}.address) memberZones;
          };
        };

        secrets.applications."wireguard/${hostname}" = {
          inherit (config.users.users.systemd-network) group;

          owner = config.users.users.systemd-network.name;
        };
      };
    };
}
