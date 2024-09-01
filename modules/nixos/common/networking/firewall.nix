{
  config,
  lib,
  ...
}: let
  inherit
    (lib)
    any
    attrNames
    concatStringsSep
    filterAttrs
    flatten
    isAttrs
    length
    mapAttrs
    mapAttrsToList
    mkIf
    mkOption
    optionalString
    pipe
    types
    ;

  cfg = config.modulo.networking.firewall;
in {
  options.modulo.networking.firewall = {
    rateLimit = {
      banTime = mkOption {
        type = types.str;
        default = "1h";
        description = ''
          Duration for which to drop all incoming packets
          from rate limit violators.
        '';
      };
    };

    forwardedInterfaces = mkOption {
      type = types.listOf types.str;
      default = [];
      description = ''
        Interfaces that have their traffic forwarded through the main outgoing interface.
      '';
    };
  };

  config.networking = mkIf config.modulo.networking.enable {
    nftables = {
      enable = true;

      tables.firewall = let
        forwardedInterfaces =
          attrNames (
            filterAttrs
            (_: {dhcp, ...}: dhcp == "server")
            config.modulo.networking.interfaces
          )
          ++ cfg.forwardedInterfaces;

        mkSet = values: "{ ${concatStringsSep ", " (map (value: "\"${value}\"") values)} }";

        mkForwardedInterfacesRule = criteria: rule:
          optionalString
          (forwardedInterfaces != [])
          "${criteria} ${mkSet forwardedInterfaces} ${rule}";

        mkForwardedInterfacesInputRule = mkForwardedInterfacesRule "iifname";

        crossContainer =
          optionalString
          (length (attrNames config.modulo.headless.containers.activatedConfigurations) > 1)
          ''iifname "ve-*" oifname "ve-*" accept'';

        publicServices = pipe config.modulo.networking.interfaces [
          (mapAttrs (_: {exposedPorts, ...}: exposedPorts))
          (mapAttrsToList (name:
            map (portConfig: let
              extendedConfig = isAttrs portConfig;

              port =
                toString
                (
                  if extendedConfig
                  then portConfig.name
                  else portConfig
                );

              type =
                if extendedConfig
                then portConfig.type
                else "tcp";

              rateLimiter = optionalString (extendedConfig && portConfig.rateLimit != null) ''
                ct state new \
                  iifname ${name} \
                  tcp dport ${port} \
                  add @flood { ip saddr . tcp dport limit rate over ${portConfig.rateLimit} } \
                  add @banned { ip saddr } \
                  drop
              '';
            in ''
              ${rateLimiter}
              iifname ${name} ${type} dport ${port} accept
            '')))
          flatten
          (concatStringsSep "\n")
        ];

        rateLimitEnabled = pipe config.modulo.networking.interfaces [
          (mapAttrs (_: {exposedPorts, ...}: exposedPorts))
          (filterAttrs (_: any (port: isAttrs port && port.rateLimit != null)))
          (val: val != {})
        ];
      in {
        family = "inet";

        content = ''
          ${optionalString rateLimitEnabled ''
            set banned {
              type ipv4_addr
              flags dynamic
              timeout ${cfg.rateLimit.banTime}
            }

            set flood {
              type ipv4_addr . inet_service
              flags dynamic
              timeout 1m
            }
          ''}

          chain input {
            type filter hook input priority 0; policy drop;

            # Block banned addresses from accessing resources.
            ${optionalString rateLimitEnabled "ip saddr @banned drop"}

            # Accept correct connections and immediately drop invalid ones
            ct state vmap { established : accept, related : accept, invalid : drop }

            # Accept any loopback traffic
            iifname lo accept

            # Accept all ICMP traffic
            meta l4proto icmp accept
            meta l4proto ipv6-icmp accept

            # Accept DHCPv6 on the link-local scope.
            ip6 saddr fe80::/10 udp dport dhcpv6-client accept

            # Accept traffic to ports exposed by the network interface configuration.
            ${publicServices}
          }

          chain output {
            type filter hook output priority 0; policy accept;
          }

          chain forward {
            type filter hook forward priority 0; policy drop;

            # Accept correct connections and immediately drop invalid ones
            ct state vmap { established : accept, related : accept, invalid : drop }

            # Forward cross-container packets
            ${crossContainer}

            # Accept packets that interact with the forwarded interfaces
            ${mkForwardedInterfacesInputRule "accept"}
          }

          chain postrouting {
            type nat hook postrouting priority 100; policy accept;

            # Enable forwarded interfaces IP masquerade
            ${mkForwardedInterfacesInputRule "masquerade random"}
          }
        '';
      };
    };

    firewall.enable = false;
  };
}
