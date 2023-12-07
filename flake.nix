{
  description = "NixOS modules collection";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";

    home-manager.url = "github:nix-community/home-manager/release-23.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence.url = "github:nix-community/impermanence";

    snowfall = {
      url = "github:snowfallorg/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    snowfall,
    ...
  } @ inputs:
    snowfall.mkFlake {
      inherit inputs;

      src = ./.;

      channels-config.allowUnfree = true;

      outputs-builder = channels: let
        inherit (channels.nixpkgs) alejandra deadnix lib runCommand statix;
        inherit (lib) getExe;
      in {
        formatter = channels.nixpkgs.alejandra;

        checks = let
          mkCheck = linter:
            runCommand "lint" {} ''
              ${linter} 2>&1
              touch $out
            '';
        in {
          fmt-check = mkCheck "${getExe alejandra} -c ${self}";
          statix = mkCheck "${getExe statix} check ${self}";
          deadnix = mkCheck "${getExe deadnix} -f ${self}";
        };
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
