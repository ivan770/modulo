{
  bwrap-bpf-filter,
  lib,
  runCommand,
  stdenv,
}:
{ nestedSandboxing }:
let
  generator = bwrap-bpf-filter.packages.${stdenv.buildPlatform.system}.default;
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
    bwrap-bpf-filter ${targetArch.${stdenv.hostPlatform.system}} \
      $out ${lib.concatStringsSep " " flags}
  ''
