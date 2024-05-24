_: {
  # Disable local documentation
  documentation = {
    enable = false;
    doc.enable = false;
    info.enable = false;
    man.enable = false;
    nixos.enable = false;
  };

  # Disable linked libraries assistance on non-Nix binary invocation
  environment.stub-ld.enable = false;

  # Disable package search on a missing command
  programs.command-not-found.enable = false;

  # journald has built-in log rotation capabilities
  services.logrotate.enable = false;

  # Disable software that is already included with the Home Manager
  xdg = {
    autostart.enable = false;
    icons.enable = false;
    menus.enable = false;
    mime.enable = false;
    sounds.enable = false;
  };
}
