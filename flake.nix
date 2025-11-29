{
  description = "NixOS modules collection";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager/release-25.11";
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

    slicer = {
      url = "github:ivan770/slicer";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils-plus";
      };
    };

    nix-colors.url = "github:Misterio77/nix-colors";
    nix-colors.inputs.nixpkgs-lib.follows = "nixpkgs";

    flake-utils-plus.url = "github:gytis-ivaskevicius/flake-utils-plus";
    snowfall = {
      url = "github:snowfallorg/lib";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils-plus.follows = "flake-utils-plus";
      };
    };
  };

  outputs =
    {
      snowfall,
      ...
    }@inputs:
    snowfall.mkFlake {
      inherit inputs;

      src = ./.;

      channels-config.allowUnfree = true;

      outputs-builder = channels: {
        formatter = channels.nixpkgs.nixfmt-tree;
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
