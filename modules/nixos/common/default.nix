{ lib, ... }:
{
  # Usually Git is installed user-wide and repositories
  # are created without being "shared", leading to
  # "repository not owned by current user" errors.
  #
  # To fix that, a global gitconfig with wildcard
  # safe.directory is installed even if the system-wide
  # Git is not installed.
  environment.etc."gitconfig".text = ''
    [safe]
      directory = "*"
  '';

  # Delegate all systemd-logind actions to WMs
  services.logind =
    lib.modulo.recursiveMerge (
      map
        (button: {
          "${button}Key" = "ignore";
          "${button}KeyLongPress" = "ignore";
        })
        [
          "hibernate"
          "power"
          "reboot"
          "suspend"
        ]
    )
    // {
      killUserProcesses = true;
    };
}
