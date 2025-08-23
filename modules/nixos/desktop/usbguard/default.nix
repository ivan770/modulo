{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.modulo.desktop.usbguard;
in
{
  options.modulo.desktop.usbguard = {
    enable = mkEnableOption "USBGuard support";
  };

  config.services.usbguard = mkIf cfg.enable {
    enable = true;
    IPCAllowedGroups = [ "wheel" ];

    # Allow all devices by default, as the primary purpose of USBGuard
    # in this configuration is to utilize it on lock screen only.
    implicitPolicyTarget = "allow";
  };
}
