{
  config,
  lib,
  ...
}: let
  inherit (lib) elem filterAttrs genAttrs mapAttrsToList mkIf pipe strings;

  supportedShells = [
    "fish"
    "zsh"
  ];

  activatedShells = pipe config.users.users [
    (filterAttrs (_: user: user.isNormalUser))
    (mapAttrsToList (_: user: strings.getName user.shell))
  ];

  programs = genAttrs supportedShells (shell: {
    enable = mkIf (elem shell activatedShells) true;
  });
in {
  inherit programs;
}
