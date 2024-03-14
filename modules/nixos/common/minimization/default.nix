_: {
  # Disable local documentation
  documentation = {
    enable = false;
    doc.enable = false;
    info.enable = false;
    man.enable = false;
    nixos.enable = false;
  };

  # Disable package search on a missing command
  programs.command-not-found.enable = false;

  # journald has built-in log rotation capabilities
  services.logrotate.enable = false;
}
