{
  inputs,
  lib,
  ...
}:
pkgs: prev: {
  mkNixPak = inputs.nixpak.lib.nixpak {
    inherit lib pkgs;
  };

  bpfFilter = prev.callPackage ./bpfFilter.nix {
    inherit (inputs) bwrap-bpf-filter;
  };
}
