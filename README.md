# Modulo

![Nix Badge](https://img.shields.io/badge/built_with-nix-blue)
![GitHub License](https://img.shields.io/github/license/ivan770/modulo)

A collection of NixOS and Home Manager modules that I use
on my own devices.

- [x] Declarative filesystem support with [Disko](https://github.com/nix-community/disko/)
- [x] Impermanence with root filesystem mounted as a `tmpfs`
- [x] Configurable networking using only systemd-based components (networkd, resolved, etc.)
- [x] WireGuard mesh private network support
- [x] Pre-configured desktop and server configurations

## Usage

Include Modulo as a flake input in your system configuration:

```nix
inputs = {
  modulo.url = "github:ivan770/modulo";

  # Optional, but highly recommended.
  nixpkgs.follows = "modulo/nixpkgs";
  unstable.follows = "modulo/unstable";
  home-manager.follows = "modulo/home-manager";
  snowfall.follows = "modulo/snowfall";

  # ...
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
