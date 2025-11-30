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
  services.logind.settings.Login =
    lib.modulo.recursiveMerge (
      map
        (button: {
          "Handle${button}Key" = "ignore";
          "Handle${button}KeyLongPress" = "ignore";
        })
        [
          "Hibernate"
          "Power"
          "Reboot"
          "Suspend"
        ]
    )
    // {
      KillUserProcesses = true;
    };
}
