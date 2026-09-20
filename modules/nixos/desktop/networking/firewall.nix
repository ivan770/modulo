{
  config,
  lib,
  ...
}:
{
  config.networking = lib.mkIf (config.modulo.networking.enable && config.modulo.desktop.enable) {
    nftables = {
      enable = true;

      tables.firewall =
        let
          ipv4Lan = [
            "10.0.0.0/8"
            "172.16.0.0/12"
            "192.168.0.0/16"
            "169.254.0.0/16"
          ];

          ipv6Lan = [
            "fd00::/8"
            "fe80::/10"
          ];
        in
        {
          family = "inet";

          content = ''
            set lan_v4 {
              type ipv4_addr
              flags interval
              elements = { ${lib.concatStringsSep ", " ipv4Lan} }
            }

            set lan_v6 {
              type ipv6_addr
              flags interval
              elements = { ${lib.concatStringsSep ", " ipv6Lan} }
            }

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

              # Allow mDNS connections.
              udp dport mdns ip daddr 224.0.0.251 accept
              udp dport mdns ip6 daddr ff02::fb accept

              # Allow local network connections for SSH, media remote control.
              ip saddr @lan_v4 accept
              ip6 saddr @lan_v6 accept
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
