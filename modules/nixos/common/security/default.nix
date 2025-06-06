{
  lib,
  pkgs,
  ...
}:
{
  environment = {
    defaultPackages = lib.mkForce [ ];
    systemPackages = [ pkgs.doas-sudo-shim ];
  };

  systemd.coredump.extraConfig = ''
    Storage=none
    ProcessSizeMax=0
  '';

  security = {
    doas = {
      enable = true;

      # Using nixos-rebuild with --use-remote-sudo requires entering password
      # multiple times, which is annoying. To prevent that, doas is instructed to
      # remember password authentications for some short time.
      extraRules = lib.mkForce [
        {
          groups = [ "wheel" ];
          persist = true;
        }
      ];
    };

    sudo.enable = false;
  };
}
