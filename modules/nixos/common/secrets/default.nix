{inputs, ...}: {
  imports = [
    inputs.sops-nix.nixosModules.sops
  ];

  # FIXME: Abstract secrets module
}
