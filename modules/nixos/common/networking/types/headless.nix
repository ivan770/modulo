{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    isString
    mapAttrs'
    mkIf
    mkOption
    nameValuePair
    optionalAttrs
    substring
    types
    ;

  inherit (lib.modulo) recursiveMerge;

  inherit (builtins) hashString;

  cfg = config.modulo.networking;
in
{
  options.modulo.networking = {
    interfaces = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            dhcp = mkOption {
              type =
                with types;
                nullOr (enum [
                  "client"
                  "server"
                ]);
              default = "client";
              description = ''
                Preferred DHCP mode on the current interface.
                Null value disables DHCP support altogether.
              '';
            };

            address = mkOption {
              type = with types; listOf str;
              default = [ ];
              description = ''
                Static IPv4 or IPv6 addresses.
              '';
            };

            dhcpClient = {
              dns = mkOption {
                type = types.bool;
                default = true;
                description = ''
                  Whether to use DNS server information received from DHCP server.
                '';
              };

              anonymize = mkOption {
                type = types.bool;
                default = true;
                description = ''
                  Whether to anonymize DHCP requests to reduce fingerprinting.
                '';
              };
            };

            dhcpServer = {
              poolSize = mkOption {
                type = types.ints.positive;
                default = 32;
                description = ''
                  Total IP address DHCP pool size.
                '';
              };

              poolOffset = mkOption {
                type = types.ints.positive;
                default = 1;
                description = ''
                  IP address offset for usage in the DHCP address pool.
                '';
              };

              dns = mkOption {
                type = with types; nullOr str;
                default = null;
                description = ''
                  DNS server to emit during DHCP responses.
                  Null value disables this feature.
                '';
              };
            };

            onlineStatus = mkOption {
              type =
                with types;
                nullOr (enum [
                  "dormant"
                  "carrier"
                  "degraded"
                  "routable"
                ]);
              default = "carrier";
              description = ''
                Online status used to determine whether the current interface is online or not.
                Null value ignores this interface when considering whether the whole system is online or not.
              '';
            };

            macAddress = mkOption {
              type = with types; nullOr str;
              default = null;
              description = ''
                Set MAC address for the current interface.
                Null value implies the usage of the default MAC address value.
              '';
            };

            macAddressPolicy = mkOption {
              type =
                with types;
                enum [
                  "auto"
                  "random"
                  "none"
                ];
              default = "auto";
              description = ''
                Set the MAC address policy if the `macAddress` value is not provided.
                `auto` utilizes random MAC address if the DHCP client anonymization is enabled.
              '';
            };

            exposedPorts = mkOption {
              type =
                with types;
                listOf (
                  either str (
                    either port (submodule {
                      options = {
                        name = mkOption {
                          type = either str port;
                          description = ''
                            Port identifier (either a number or a well-known service name).
                          '';
                        };

                        type = mkOption {
                          type = enum [
                            "tcp"
                            "udp"
                          ];
                          default = "tcp";
                          description = ''
                            Port type (TCP or UDP).
                          '';
                        };

                        rateLimit = mkOption {
                          type = nullOr str;
                          default = null;
                          description = ''
                            nftables rate limit configuration, specified in a format
                            like "10/second" or "30/minute".
                          '';
                        };
                      };
                    })
                  )
                );
              default = [ ];
              description = ''
                Public services exposed via the current interface.
                You may optionally use attrs syntax to define additional parameters
                like rate limiting.
              '';
            };

            extraConfig = mkOption {
              type = types.attrs;
              default = { };
              description = ''
                Extra configuration to add to the current interface.
              '';
            };
          };
        }
      );
      default = { };
      description = ''
        Supported network interfaces.
      '';
    };
  };

  config = mkIf (cfg.enable && config.modulo.headless.enable) {
    systemd.network =
      let
        mkName = name: substring 0 8 (hashString "sha256" name);
      in
      {
        links = mapAttrs' (
          name: options:
          let
            baseConfig = {
              matchConfig.OriginalName = name;
            };

            staticMacAddress = optionalAttrs (isString options.macAddress) {
              linkConfig.MACAddress = options.macAddress;
            };

            configuredMacAddress =
              let
                shouldUseRandom =
                  options.macAddressPolicy == "random"
                  || (options.macAddressPolicy == "auto" && options.dhcp == "client" && options.dhcpClient.anonymize);
              in
              optionalAttrs (options.macAddress == null) {
                linkConfig.MACAddressPolicy = if shouldUseRandom then "random" else "none";
              };
          in
          nameValuePair "10-${mkName name}" (recursiveMerge [
            baseConfig
            staticMacAddress
            configuredMacAddress
          ])
        ) cfg.interfaces;

        networks = mapAttrs' (
          name: options:
          let
            baseConfig = {
              inherit name;
              inherit (options) address;

              enable = true;

              matchConfig.Name = name;

              networkConfig = {
                LLMNR = false;
                MulticastDNS = false;

                LinkLocalAddressing = "ipv6";
                IPv6AcceptRA = true;
              };

              linkConfig = {
                RequiredForOnline = if (options.onlineStatus == null) then "no" else options.onlineStatus;
              };

              # By default, networks managed by networkd use noqueue.
              # Most Linux distros use fq-codel by default.
              fairQueueingControlledDelayConfig.Parent = "root";

              # FIXME: Is DHCPv6 really necessary?
              ipv6AcceptRAConfig.DHCPv6Client = "always";
            };

            dhcpClient = optionalAttrs (options.dhcp == "client") {
              networkConfig.DHCP = "yes";
            };

            linkDNS = optionalAttrs (options.dhcp == "client" && !options.dhcpClient.dns) {
              dhcpV4Config.UseDNS = false;
              dhcpV6Config.UseDNS = false;
              ipv6AcceptRAConfig.UseDNS = false;
            };

            anonymize = optionalAttrs (options.dhcp == "client" && options.dhcpClient.anonymize) {
              dhcpV4Config.Anonymize = true;

              # Anonymize is not available for DHCPv6 according to the documentation.
              # The values here are also limited by the nixpkgs config checker.
              dhcpV6Config = {
                RapidCommit = false;
                SendHostname = false;
                UseNTP = false;
              };
            };

            dhcpServer = optionalAttrs (options.dhcp == "server") {
              networkConfig = {
                DHCPServer = "yes";

                # Assume that packet forwarding is required on interfaces
                # that have DHCP server enabled.
                IPMasquerade = "both";
              };

              dhcpServerConfig =
                let
                  EmitDNS = isString options.dhcpServer.dns;
                in
                {
                  inherit EmitDNS;

                  PoolSize = options.dhcpServer.poolSize;
                  PoolOffset = options.dhcpServer.poolOffset;
                }
                // optionalAttrs EmitDNS {
                  DNS = options.dhcpServer.dns;
                };
            };
          in
          nameValuePair (mkName name) (recursiveMerge [
            baseConfig
            dhcpClient
            linkDNS
            anonymize
            dhcpServer
            options.extraConfig
          ])
        ) cfg.interfaces;

        wait-online.enable = false;
      };

    networking = {
      dhcpcd.enable = false;
      networkmanager.enable = false;
      useDHCP = false;

      useNetworkd = true;
    };
  };
}
