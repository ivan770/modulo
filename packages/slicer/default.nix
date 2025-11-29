{
  inputs,
  stdenv,
}:
inputs.slicer.packages.${stdenv.hostPlatform.system}.default
