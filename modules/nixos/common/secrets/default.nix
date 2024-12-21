{
  config,
  lib,
  inputs,
  ...
}: let
  inherit
    (lib)
    flatten
    genAttrs
    listToAttrs
    mapAttrs
    mapAttrs'
    mapAttrsToList
    nameValuePair
    mkOption
    types
    ;

  cfg = config.modulo.secrets;
in {
  imports = [
    inputs.sops-nix.nixosModules.sops
    ./users.nix
  ];

  options.modulo.secrets = {
    sopsFile = mkOption {
      type = types.path;
      description = ''
        SOPS file that stores encrypted secrets.
      '';
    };

    applications = mkOption {
      type = with types;
        attrsOf (submodule (opts: {
          options = {
            owner = mkOption {
              type = str;
              default = "root";
              description = ''
                Secret owner name.
              '';
            };

            group = mkOption {
              type = str;
              default = config.users.users.${opts.config.owner}.group;
              description = ''
                Secret group name.
              '';
            };

            neededForUsers = mkOption {
              type = bool;
              default = false;
              description = ''
                Decrypt the secret before user and group creation.
                This is required for user password secrets.
              '';
            };
          };
        }));
      default = {};
      description = ''
        Application-specific secrets that are expected to be provided by hosts.
      '';
    };

    mapping = mkOption {
      type = with types; attrsOf (either bool str);
      default = {};
      description = ''
        Mapping from application secrets to secret names.
      '';
    };

    values = mkOption {
      type = types.attrsOf types.path;
      readOnly = true;
      description = ''
        Secret values.
      '';
    };
  };

  config = let
    mkSecretName = name:
      if cfg.mapping.${name}
      then name
      else cfg.mapping.${name};
  in {
    home-manager.users =
      mapAttrs
      (user: _: {
        modulo.secrets.values =
          genAttrs
          config.home-manager.users.${user}.modulo.secrets.applications
          (application: cfg.values."users/${user}/${application}");
      })
      config.snowfallorg.users;

    sops = {
      defaultSopsFile = cfg.sopsFile;

      validateSopsFiles = config.modulo.filesystem.type == "standard";

      secrets =
        mapAttrs'
        (name: nameValuePair (mkSecretName name))
        cfg.applications;
    };

    modulo.secrets = {
      applications = listToAttrs (
        flatten (mapAttrsToList
          (user: _:
            map (application:
              nameValuePair "users/${user}/${application}" {
                inherit (config.users.users.${user}) group;

                owner = config.users.users.${user}.name;
              })
            config.home-manager.users.${user}.modulo.secrets.applications)
          config.snowfallorg.users)
      );

      values =
        mapAttrs
        (name: _: config.sops.secrets.${mkSecretName name}.path)
        cfg.applications;
    };
  };
}
