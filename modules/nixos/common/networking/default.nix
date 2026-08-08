{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  cfg = config.modulo.networking;
in
{
  options.modulo.networking = {
    enable = mkEnableOption "managed networking stack";

    keepalive = {
      time = mkOption {
        type = types.ints.positive;
        default = if config.modulo.headless.enable then 600 else 7200;
        defaultText = ''
          if config.modulo.headless.enable then 600 else 7200;
        '';
        description = ''
          Seconds to wait before sending keepalive probes for inactive TCP connections.
        '';
      };

      interval = mkOption {
        type = types.ints.positive;
        default = if config.modulo.headless.enable then 60 else 75;
        defaultText = ''
          if config.modulo.headless.enable then 60 else 75;
        '';
        description = ''
          Seconds to wait between each keepalive probe.
        '';
      };

      probes = mkOption {
        type = types.ints.positive;
        default = if config.modulo.headless.enable then 5 else 9;
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
    ./types/desktop.nix
    ./types/headless.nix

    ./dns.nix
    ./firewall.nix
    ./wireguard.nix
  ];

  config = mkIf cfg.enable {
    systemd.network.wait-online.enable = false;

    boot.kernel.sysctl = {
      # Network congestion configuration
      "net.ipv4.tcp_congestion_control" = "cubic";
      "net.ipv4.tcp_ecn" = 1;

      # TCP keepalive configuration
      "net.ipv4.tcp_keepalive_time" = cfg.keepalive.time;
      "net.ipv4.tcp_keepalive_intvl" = cfg.keepalive.interval;
      "net.ipv4.tcp_keepalive_probes" = cfg.keepalive.probes;

      # Ignore incoming ICMP redirects
      "net.ipv4.conf.all.accept_redirects" = false;
      "net.ipv4.conf.default.accept_redirects" = false;
      "net.ipv4.conf.all.secure_redirects" = false;
      "net.ipv4.conf.default.secure_redirects" = false;
      "net.ipv6.conf.all.accept_redirects" = false;
      "net.ipv6.conf.default.accept_redirects" = false;

      # Disable outgoing ICMP redirects
      "net.ipv4.conf.all.send_redirects" = false;
      "net.ipv4.conf.default.send_redirects" = false;

      # Disable "source routing"
      "net.ipv4.conf.all.accept_source_route" = false;
      "net.ipv4.conf.default.accept_source_route" = false;
      "net.ipv6.conf.all.accept_source_route" = false;
      "net.ipv6.conf.default.accept_source_route" = false;

      # Ignore incoming ICMP echo requests
      "net.ipv4.icmp_echo_ignore_all" = true;
      "net.ipv6.icmp.echo_ignore_all" = true;

      # RFC 3704 (strict reverse path filtering)
      "net.ipv4.conf.all.rp_filter" = 1;
      "net.ipv4.conf.default.rp_filter" = 1;

      # RFC 1337 (TCP time-wait assassination)
      "net.ipv4.tcp_rfc1337" = true;

      # SYN flood attacks prevention
      "net.ipv4.tcp_syncookies" = true;
    };

    networking = {
      dhcpcd.enable = false;
      useDHCP = false;
    };
  };
}
