{
  description = "NixOS modules collection";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    disko = {
      url = "github:nix-community/disko/v1.11.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence.url = "github:nix-community/impermanence";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpak.url = "github:ivan770/nixpak";
    nixpak.inputs.nixpkgs.follows = "nixpkgs";

    bwrap-bpf-filter = {
      url = "github:ivan770/bwrap-bpf-filter";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils-plus";
      };
    };

    nix-colors.url = "github:Misterio77/nix-colors";
    nix-colors.inputs.nixpkgs-lib.follows = "nixpkgs";

    flake-utils-plus.url = "github:gytis-ivaskevicius/flake-utils-plus";
    flake-compat.url = "github:edolstra/flake-compat";
    snowfall = {
      url = "github:snowfallorg/lib/v3.0.3";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils-plus.follows = "flake-utils-plus";
        flake-compat.follows = "flake-compat";
      };
    };
  };

  outputs = {
    nixpkgs,
    snowfall,
    ...
  } @ inputs:
    snowfall.mkFlake {
      inherit inputs;

      src = ./.;

      channels-config.allowUnfree = true;

      outputs-builder = channels: {
        formatter = channels.nixpkgs.alejandra;
      };

      snowfall = {
        namespace = "modulo";

        meta = {
          name = "modulo";
          title = "Modulo";
        };
      };
    };
}
