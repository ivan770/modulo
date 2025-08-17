{
  lib,
  ...
}:
{
  environment = {
    defaultPackages = lib.mkForce [ ];
    systemPackages = [ ];
  };

  systemd.coredump.extraConfig = ''
    Storage=none
    ProcessSizeMax=0
  '';

  # Use run0.
  security.sudo.enable = false;
}
