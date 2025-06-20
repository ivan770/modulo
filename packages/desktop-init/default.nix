{
  coreutils,
  findutils,
  gnused,
  systemdMinimal,
  writeShellApplication,
}:
writeShellApplication {
  name = "desktop-init";

  runtimeInputs = [
    coreutils
    findutils
    gnused
    systemdMinimal
  ];

  excludeShellChecks = [ "SC2086" ];

  # Default bashOptions prevent /etc/profile from being sourced.
  bashOptions = [ ];

  text = ''
    systemctl --user reset-failed

    currentenv=$(printenv | sed 's/=.*//' | xargs)
    systemctl --user import-environment $currentenv

    systemctl --user start wayland-wm.service --wait
    systemctl --user start graphical-session-post.target

    systemctl --user unset-environment $currentenv
  '';
}
