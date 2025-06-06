{
  buildPlatform,
  bwrap-bpf-filter,
  hostPlatform,
  lib,
  runCommand,
}:
{ nestedSandboxing }:
let
  generator = bwrap-bpf-filter.packages.${buildPlatform.system}.default;
  flags = lib.optional nestedSandboxing "--nested-sandboxing";

  targetArch = {
    "x86_64-linux" = "x86-64";
  };
in
runCommand "modulo-sandbox-bpf"
  {
    nativeBuildInputs = [ generator ];
  }
  ''
    bwrap-bpf-filter ${targetArch.${hostPlatform.system}} \
      $out ${lib.concatStringsSep " " flags}
  ''
