{lib, ...}: let
  inherit (lib) mkOption types;
in {
  options.modulo.filesystem = {
    type = mkOption {
      type = types.enum ["standard" "image"];
      default = "standard";
    };
  };
}
