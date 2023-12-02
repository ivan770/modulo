{
  config,
  lib,
  ...
}: let
  inherit (lib) mkIf mkOption types;

  cfg = config.modulo.firmware;
in {
  options.modulo.firmware = {
    cpu.vendor = mkOption {
      type = types.nullOr (types.enum ["amd" "intel"]);
      description = "CPU vendor";
      example = "amd";
    };
  };

  config.hardware = {
    enableRedistributableFirmware = true;

    cpu = mkIf (cfg.cpu.vendor != null) {
      ${cfg.cpu.vendor}.updateMicrocode = true;
    };
  };
}
