{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkDefault mkEnableOption mkIf;

  cfg = config.modulo.headless;
in {
  options.modulo.headless = {
    enable = mkEnableOption "generic headless configuration";
  };

  config = mkIf cfg.enable {
    boot = {
      kernel.sysctl = {
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

      kernelPackages = mkDefault pkgs.linuxPackages_hardened;
    };

    security.protectKernelImage = true;
  };
}
