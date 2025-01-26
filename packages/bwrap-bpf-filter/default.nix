{
  inputs,
  stdenvNoCC,
  ...
}:
inputs.bwrap-bpf-filter.packages.${stdenvNoCC.hostPlatform.system}.default
