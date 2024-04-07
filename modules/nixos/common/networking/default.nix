{
  config,
  lib,
  ...
}: let
  inherit
    (lib)
    isString
    mapAttrs'
    mkEnableOption
    mkIf
    mkOption
    nameValuePair
    optionalAttrs
    types
    ;

  inherit (lib.modulo) recursiveMerge;

  inherit (builtins) hashString;

  cfg = config.modulo.networking;
in {
  options.modulo.networking = {
    enable = mkEnableOption "managed networking stack";

    interfaces = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          dhcp = mkOption {
            type = with types;
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
            default = [];
            description = ''
              Static IPv4 or IPv6 addresses.
            '';
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

          wireless = mkEnableOption "wireless networking support for the current interface";

          onlineStatus = mkOption {
            type = with types;
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

          exposedPorts = mkOption {
            type = with types;
              listOf (either str (either port (submodule {
                options = {
                  name = mkOption {
                    type = either str port;
                    description = ''
                      Port identifier (either a number or a well-known service name).
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
              })));
            default = ["ssh"];
            description = ''
              Public services exposed via the current interface.
              You may optionally use attrs syntax to define additional parameters
              like rate limiting.
            '';
          };

          extraConfig = mkOption {
            type = types.attrs;
            default = {};
            description = ''
              Extra configuration to add to the current interface.
            '';
          };
        };
      });
      default = {};
      description = ''
        Supported network interfaces.
      '';
    };

    keepalive = {
      time = mkOption {
        type = types.ints.positive;
        default =
          if config.modulo.headless.enable
          then 600
          else 7200;
        defaultText = ''
          if config.modulo.headless.enable then 600 else 7200;
        '';
        description = ''
          Seconds to wait before sending keepalive probes for inactive TCP connections.
        '';
      };

      interval = mkOption {
        type = types.ints.positive;
        default =
          if config.modulo.headless.enable
          then 60
          else 75;
        defaultText = ''
          if config.modulo.headless.enable then 60 else 75;
        '';
        description = ''
          Seconds to wait between each keepalive probe.
        '';
      };

      probes = mkOption {
        type = types.ints.positive;
        default =
          if config.modulo.headless.enable
          then 5
          else 9;
        defaultText = ''
          if config.modulo.headless.enable then 5 else 9;
        '';
        description = ''
          The amount of probes to be sent before closing an inactive TCP connection.
        '';
      };
    };
  };

  imports = [
    ./dns.nix
    ./firewall.nix
    ./wireless.nix
  ];

  config = mkIf cfg.enable {
    systemd.network = {
      networks = mapAttrs' (name: options: let
        baseConfig = {
          inherit name;
          inherit (options) address;

          enable = true;

          networkConfig =
            {
              LLMNR = false;
              MulticastDNS = false;

              LinkLocalAddressing = "ipv6";
              IPv6AcceptRA = true;
            }
            // optionalAttrs options.wireless {
              # Wireless networks may have an extended downtime period,
              # so we wait for 5 seconds before losing carrier status for the current interface.
              IgnoreCarrierLoss = "5s";
            };

          linkConfig =
            {
              RequiredForOnline =
                if (options.onlineStatus == null)
                then "no"
                else options.onlineStatus;
            }
            // optionalAttrs (isString options.macAddress) {
              MACAddress = options.macAddress;
            };

          ipv6AcceptRAConfig.DHCPv6Client = "always";
        };

        dhcpClient = optionalAttrs (options.dhcp == "client") {
          networkConfig.DHCP = "yes";
        };

        localDns = optionalAttrs (options.dhcp == "client" && cfg.dns.private) {
          dhcpV4Config.UseDNS = false;
          dhcpV6Config.UseDNS = false;
          ipv6AcceptRAConfig.UseDNS = false;
        };

        dhcpServer = optionalAttrs (options.dhcp == "server") {
          networkConfig = {
            DHCPServer = "yes";

            # Assume that packet forwarding is required on interfaces
            # that have DHCP server enabled.
            IPMasquerade = "both";
          };

          dhcpServerConfig = let
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
        nameValuePair (hashString "md5" name) (recursiveMerge [
          baseConfig
          dhcpClient
          localDns
          dhcpServer
          options.extraConfig
        ]))
      cfg.interfaces;

      wait-online.enable = false;
    };

    boot.kernel.sysctl = {
      # Use TCP BBR congestion control algorithm
      "net.core.default_qdisc" = "fq";
      "net.ipv4.tcp_congestion_control" = "bbr";

      # TCP keepalive configuration
      "net.ipv4.tcp_keepalive_time" = cfg.keepalive.time;
      "net.ipv4.tcp_keepalive_intvl" = cfg.keepalive.interval;
      "net.ipv4.tcp_keepalive_probes" = cfg.keepalive.probes;

      # Ignore incoming ICMP redirects
      "net.ipv4.conf.all.accept_redirects" = 0;
      "net.ipv4.conf.default.accept_redirects" = 0;
      "net.ipv4.conf.all.secure_redirects" = 0;
      "net.ipv4.conf.default.secure_redirects" = 0;
      "net.ipv6.conf.all.accept_redirects" = 0;
      "net.ipv6.conf.default.accept_redirects" = 0;

      # Disable outgoing ICMP redirects
      "net.ipv4.conf.all.send_redirects" = 0;
      "net.ipv4.conf.default.send_redirects" = 0;

      # Ignore incoming ICMP echo requests
      "net.ipv4.icmp_echo_ignore_all" = 1;
      "net.ipv6.icmp.echo_ignore_all" = 1;

      # RFC 3704 (strict reverse path filtering)
      "net.ipv4.conf.all.rp_filter" = 1;
      "net.ipv4.conf.default.rp_filter" = 1;

      # RFC 1337 (TCP time-wait assassination)
      "net.ipv4.tcp_rfc1337" = 1;
    };

    networking = {
      dhcpcd.enable = false;
      networkmanager.enable = false;
      useDHCP = false;

      useNetworkd = true;
    };
  };
}
