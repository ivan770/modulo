{
  lib,
  pkgs,
  ...
}:
let
  sudoShim = pkgs.writeShellScriptBin "sudo" ''
    run0 --background= "$@"
  '';
in
{
  environment = {
    defaultPackages = lib.mkForce [ ];
    systemPackages = [ sudoShim ];
  };

  systemd.coredump.extraConfig = ''
    Storage=none
    ProcessSizeMax=0
  '';

  security = {
    # Polkit is required for run0 to function properly.
    polkit.enable = true;

    # Use run0.
    sudo.enable = false;
  };
}
