{
  inputs,
  lib,
  ...
}:
pkgs: prev:
let
  src = pkgs.applyPatches {
    name = "patched-nixpak";
    src = inputs.nixpak;

    patches = [
      (pkgs.fetchpatch2 {
        url = "https://github.com/nixpak/nixpak/commit/960898f79e83aa68c75876794450019ddfdb9157.patch";
        hash = "sha256-mojc/KTgfp1LWU6uY1+YeyGEKO2yak8NI89WT3vo89k=";
      })
    ];
  };

  # builtins.getFlake doesn't support derivations, but flake-compat provides
  # practically the same behavior without this restriction.
  patchedNixpak = import inputs.flake-compat {
    inherit src;
  };
in
{
  mkNixPak = patchedNixpak.outputs.lib.nixpak {
    inherit lib pkgs;
  };

  bpfFilter = prev.callPackage ./bpfFilter.nix {
    inherit (inputs) bwrap-bpf-filter;
  };
}
