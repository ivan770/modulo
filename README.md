# Modulo

![Nix Badge](https://img.shields.io/badge/built_with-nix-blue)
![GitHub License](https://img.shields.io/github/license/ivan770/modulo)

A collection of NixOS and Home Manager modules that I use
on my own devices.

[x] Declarative filesystem support with [Disko](https://github.com/nix-community/disko/)
[x] Impermanence with root filesystem mounted as a `tmpfs`
[x] Configurable networking using only systemd-based components (networkd, resolved, etc.)
[x] Pre-configured desktop and server configurations

## Usage

Include Modulo as a flake input in your system configuration:

```nix
modulo = {
  url = "github:ivan770/modulo";

  # Optional, but highly recommended.
  inputs = {
    nixpkgs.follows = "nixpkgs";
    snowfall.follows = "snowfall";
  };
};
```

Support for separate module usage is best effort, so it's recommended
to import all repository modules together.

Example (when using [Snowfall Lib](https://github.com/snowfallorg/lib)):

```nix
systems.modules.nixos = attrValues inputs.modulo.nixosModules
  ++ [inputs.home-manager.nixosModules.home-manager];
```

## License

This software is licensed under the MIT license.

