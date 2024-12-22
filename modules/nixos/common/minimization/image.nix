{
  config,
  lib,
  ...
}:
lib.mkIf (config.modulo.filesystem.type == "image") {
  nix.enable = false;

  system = {
    disableInstallerTools = true;
    switch.enable = false;
  };
}
