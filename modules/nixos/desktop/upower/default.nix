{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.modulo.desktop.upower;
in
{
  options.modulo.desktop.upower = {
    enable = mkEnableOption "UPower support";
    batteryPolling = mkEnableOption "battery polling";
  };

  config.services.upower = mkIf cfg.enable {
    enable = true;
    ignoreLid = true;
    noPollBatteries = !cfg.batteryPolling;

    percentageLow = 20;
    percentageCritical = 5;

    allowRiskyCriticalPowerAction = true;
    criticalPowerAction = "Ignore";
  };
}
