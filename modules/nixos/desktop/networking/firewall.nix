{
  config,
  lib,
  ...
}:
{
  config.networking = lib.mkIf (config.modulo.networking.enable && config.modulo.desktop.enable) {
    nftables = {
      enable = true;

      tables.firewall = {
        family = "inet";

        content = ''
          chain input {
            type filter hook input priority 0; policy drop;

            # Accept correct connections and immediately drop invalid ones
            ct state vmap { established : accept, related : accept, invalid : drop }

            # Accept any loopback traffic
            iifname lo accept

            # Accept all ICMP traffic
            meta l4proto icmp accept
            meta l4proto ipv6-icmp accept

            # Accept DHCPv6 on the link-local scope.
            ip6 saddr fe80::/10 udp dport dhcpv6-client accept
          }

          chain output {
            type filter hook output priority 0; policy accept;
          }

          chain forward {
            type filter hook forward priority 0; policy drop;

            # Accept correct connections and immediately drop invalid ones
            ct state vmap { established : accept, related : accept, invalid : drop }
          }
        '';
      };
    };

    firewall.enable = false;
  };
}
