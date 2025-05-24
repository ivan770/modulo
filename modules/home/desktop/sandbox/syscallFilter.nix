{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.modulo.syscallFilter;
in {
  options.modulo.syscallFilter = {
    enable =
      mkEnableOption "syscall filtering"
      // {
        default = true;
      };

    nestedSandboxing = mkEnableOption "nested sandboxing support";
  };

  config.bubblewrap = mkIf cfg.enable {
    seccomp = pkgs.bpfFilter {
      inherit (cfg) nestedSandboxing;
    };
  };
}
