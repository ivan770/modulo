{
  inputs,
  stdenvNoCC,
  ...
}:
inputs.bwrap-bpf-filter.packages.${stdenvNoCC.buildPlatform.system}.default
