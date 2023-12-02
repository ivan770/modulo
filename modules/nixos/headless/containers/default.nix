{
  config,
  inputs,
  lib,
  ...
}: let
  inherit
    (lib)
    attrNames
    attrValues
    filterAttrs
    flatten
    hasAttr
    listToAttrs
    mapAttrs
    mapAttrs'
    nameValuePair
    mapAttrsToList
    mkEnableOption
    mkOption
    range
    types
    zipListsWith
    ;

  inherit (lib.modulo) recursiveMerge;

  cfg = config.modulo.headless.containers;
in {
  options.modulo.headless.containers = {
    configurations = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          config = mkOption {
            # Validation of the config type is delegated to nixpkgs.
            type = types.anything;
            description = ''
              NixOS container configuration.
            '';
          };

          bindSlots = mkOption {
            type = types.attrsOf types.str;
            default = {};
            description = ''
              Filesystem binds that have to be provisioned by an activated container configuration.
            '';
          };

          exposedServices = mkOption {
            type = types.listOf types.str;
            default = {};
            description = ''
              Container's public services.
            '';
          };

          forwardInterface = mkEnableOption "network forwarding";
        };
      });
      default = {};
      description = ''
        Supported NixOS containers.
      '';
    };

    activatedConfigurations = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          specialArgs = mkOption {
            type = types.attrs;
            default = {};
            description = ''
              Extra arguments to pass onto the NixOS container configuration.
            '';
          };
        };
      });
      default = {};
      description = ''
        Activated NixOS containers.
      '';
    };

    dataDirectory = mkOption {
      type = types.str;
      default = "/var/lib/mod-containers";
      description = ''
        Container data storage directory.
      '';
    };
  };

  config = let
    serviceConfigurations = filterAttrs (name: _: hasAttr name cfg.configurations) cfg.activatedConfigurations;

    networkConfigurations = listToAttrs (zipListsWith
      (name: number: {
        inherit name;
        value = {
          localAddress = "192.168.100.${toString number}";
          hostAddress = "192.168.101.${toString number}";
        };
      }) (attrNames serviceConfigurations) (range 1 254));

    intersectedConfigurations =
      mapAttrs (name: userConfiguration: {
        inherit userConfiguration;
        networkConfiguration =
          networkConfigurations.${name}
          // {
            exposedServices = listToAttrs (
              zipListsWith (name: value: {inherit name value;}) cfg.configurations.${name}.exposedServices (range 20000 30000)
            );
          };
        serviceConfiguration = cfg.configurations.${name};
      })
      serviceConfigurations;

    connectors = sender:
      mapAttrs
      (_: {networkConfiguration, ...}: {
        address = networkConfiguration.localAddress;
        services = networkConfiguration.exposedServices;
      })
      (filterAttrs (name: _: name != sender) intersectedConfigurations);
  in {
    assertions = [
      {
        assertion = (attrNames serviceConfigurations) == (attrNames cfg.activatedConfigurations);
        message = ''
          You can only activate containers that are defined via config.modulo.containers.configurations.
        '';
      }
    ];

    containers =
      mapAttrs (name: {
        networkConfiguration,
        serviceConfiguration,
        userConfiguration,
      }: {
        inherit (networkConfiguration) hostAddress localAddress;

        autoStart = true;
        ephemeral = true;
        privateNetwork = true;

        extraFlags =
          ["-U"]
          ++ (
            attrValues (
              mapAttrs (slot: mountPoint: "--bind ${cfg.dataDirectory}/${name}-${slot}:${mountPoint}:idmap") serviceConfiguration.bindSlots
            )
          );

        specialArgs =
          userConfiguration.specialArgs
          // {
            inherit (networkConfiguration) exposedServices localAddress;
            connectors = connectors name;
          };

        config = attrs:
          (serviceConfiguration.config attrs)
          // {
            imports = [
              inputs.self.nixosModules."common/minimization"
            ];

            i18n = {
              inherit (config.i18n) defaultLocale extraLocaleSettings;
            };

            time.timeZone = config.time.timeZone;

            system.stateVersion = config.system.stateVersion;
          };
      })
      intersectedConfigurations;

    modulo = {
      impermanence.directories = flatten (attrValues (
        mapAttrs (
          name: {serviceConfiguration, ...}:
            attrValues (
              mapAttrs (slot: _: {
                directory = "${cfg.dataDirectory}/${name}-${slot}";
                mode = "0750";
              })
              serviceConfiguration.bindSlots
            )
        )
        intersectedConfigurations
      ));

      networking.firewall.forwardedInterfaces =
        mapAttrsToList (name: _: "ve-${name}")
        (filterAttrs (
            _: {serviceConfiguration, ...}:
              serviceConfiguration.forwardInterface
          )
          intersectedConfigurations);

      headless.nginx.upstreams = recursiveMerge (attrValues (mapAttrs (
          name: {networkConfiguration, ...}:
            mapAttrs' (
              service: port: nameValuePair "${name}-${service}" "${networkConfiguration.localAddress}:${toString port}"
            )
            networkConfiguration.exposedServices
        )
        intersectedConfigurations));
    };
  };
}
