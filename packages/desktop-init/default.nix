{
  coreutils,
  findutils,
  gnused,
  lib,
  systemdMinimal,
  writeShellApplication,
}:
let
  systemctl = lib.getExe' systemdMinimal "systemctl";
  printenv = lib.getExe' coreutils "printenv";
  sed = lib.getExe' gnused "sed";
  xargs = lib.getExe' findutils "xargs";
in
writeShellApplication {
  name = "desktop-init";

  excludeShellChecks = [ "SC2086" ];

  # Default bashOptions prevent /etc/profile from being sourced.
  bashOptions = [ ];

  text = ''
    ${systemctl} --user reset-failed

    currentenv=$(${printenv} | ${sed} 's/=.*//' | ${xargs})
    ${systemctl} --user import-environment $currentenv

    ${systemctl} --user start wayland-wm.service --wait
    ${systemctl} --user start graphical-session-post.target

    ${systemctl} --user unset-environment $currentenv
  '';
}
