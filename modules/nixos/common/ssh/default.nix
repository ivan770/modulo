_: {
  services.openssh = {
    enable = true;

    startWhenNeeded = true;
    allowSFTP = false;
    authorizedKeysInHomedir = false;

    settings = {
      AllowStreamLocalForwarding = false;
      AllowTcpForwarding = false;
      ClientAliveInterval = 600;
      ClientAliveCountMax = 0;
      KbdInteractiveAuthentication = false;
      LogLevel = "ERROR";
      # FIXME: https://github.com/NixOS/nixpkgs/pull/323753
      LoginGraceTime = 0;
      MaxAuthTries = 2;
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      PermitUserRC = false;
      Protocol = 2;
    };
  };

  # Disable extensive failed attempt logging
  systemd.services."sshd@".serviceConfig.LogFilterPatterns = [
    "~Connection closed by remote host"
    "~Connection reset by peer"
    "~Timeout before authentication"
    "~maximum authentication attempts exceeded"
    "~banner line contains invalid characters"
    "~client sent invalid protocol identifier"
    "~Protocol major versions differ"
    "~Bad remote protocol version identification"
    "~kex protocol error"
  ];
}
