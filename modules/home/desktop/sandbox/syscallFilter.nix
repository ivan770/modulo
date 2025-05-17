{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit
    (lib)
    concatStringsSep
    mkEnableOption
    mkIf
    optional
    ;

  cfg = config.modulo.syscallFilter;

  targetArch = {
    "x86_64-linux" = "x86-64";
  };

  flags = optional cfg.nestedSandboxing "--nested-sandboxing";

  seccomp = {
    modulo,
    runCommand,
    stdenvNoCC,
  }:
    runCommand "modulo-sandbox-bpf" {
      nativeBuildInputs = [modulo.bwrap-bpf-filter];
    } ''
      bwrap-bpf-filter ${targetArch.${stdenvNoCC.hostPlatform.system}} \
        $out ${concatStringsSep " " flags}
    '';
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
    seccomp = pkgs.callPackage seccomp {};
  };
}
