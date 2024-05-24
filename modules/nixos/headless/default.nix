{lib, ...}: {
  options.modulo.headless = {
    enable = lib.mkEnableOption "generic headless configuration";
  };
}
