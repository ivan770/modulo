{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    elem
    filterAttrs
    genAttrs
    mapAttrsToList
    mkIf
    pipe
    strings
    unique
    ;

  supportedShells = [
    "fish"
    "zsh"
  ];

  activatedShells = pipe config.users.users [
    (filterAttrs (_: user: user.isNormalUser))
    (mapAttrsToList (_: user: user.shell))
    unique
  ];

  activatedShellNames = map strings.getName activatedShells;

  programs = genAttrs supportedShells (shell: {
    enable = mkIf (elem shell activatedShellNames) true;
  });
in
{
  inherit programs;

  environment.shells = activatedShells;
}
