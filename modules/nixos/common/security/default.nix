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

  # Use run0.
  security.sudo.enable = false;
}
