{
  lib,
  pkgs,
  ...
}: {
  environment = {
    defaultPackages = lib.mkForce [];
    systemPackages = [pkgs.doas-sudo-shim];
  };

  security = {
    doas.enable = true;
    sudo.enable = false;
  };
}
