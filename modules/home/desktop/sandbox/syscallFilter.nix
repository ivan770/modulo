{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) concatStringsSep mkEnableOption mkIf optional types;

  cfg = config.modulo.syscallFilter;

  targetArch = {
    "x86_64-linux" = "x86-64";
  };

  flags = optional (cfg.nestedSandboxing) "--nested-sandboxing";

  seccomp = pkgs.stdenvNoCC.mkDerivation {
    pname = "modulo-sandbox-bpf";
    version = "0.1.0";

    nativeBuildInputs = [pkgs.modulo.bwrap-bpf-filter];

    dontUnpack = true;

    buildPhase = ''
      bwrap-bpf-filter ${targetArch.${pkgs.stdenvNoCC.hostPlatform.system}} \
        $out ${concatStringsSep " " flags}
    '';
  };
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
    inherit seccomp;
  };
}
