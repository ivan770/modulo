{
  config,
  lib,
  options,
  pkgs,
  ...
}: let
  inherit
    (lib)
    concatStringsSep
    getExe
    mapAttrs
    mapAttrsToList
    mkEnableOption
    mkIf
    mkOption
    optional
    optionalAttrs
    types
    ;

  cfg = config.modulo.headless.authelia;
in {
  options.modulo.headless.authelia = {
    enable = mkEnableOption "Authelia authentication server";

    # https://github.com/NixOS/nixpkgs/blob/5de0b32be6e85dc1a9404c75131316e4ffbc634c/nixos/modules/services/security/authelia.nix#L70-L110
    jwtSecretFile = mkOption {
      type = types.path;
      description = ''
        Path to your JWT secret used during identity verificaton.
      '';
    };

    oidcIssuerPrivateKeyFile = mkOption {
      type = types.path;
      description = ''
        Path to your private key file used to encrypt OIDC JWTs.
      '';
    };

    storageEncryptionKeyFile = mkOption {
      type = types.path;
      description = ''
        Path to your storage encryption key.
      '';
    };

    host = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = ''
        Host address.
      '';
    };

    port = mkOption {
      type = types.port;
      default = 5556;
      description = ''
        Port used for application.
      '';
    };

    domain = mkOption {
      type = types.str;
      description = ''
        Domain name which will serve Authelia.
      '';
    };

    users = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          displayname = mkOption {
            type = types.str;
            description = ''
              User display name.
            '';
          };

          email = mkOption {
            type = types.str;
            description = ''
              User e-mail address.
            '';
          };

          passwordFile = mkOption {
            type = types.path;
            description = ''
              Path to user's password value.
            '';
          };
        };
      });
      description = ''
        Supported users.
      '';
    };

    oidc = {
      clients = mkOption {
        type = types.attrsOf (types.submodule {
          options = {
            redirectUris = mkOption {
              type = types.listOf types.str;
              description = ''
                Supported callback URIs.
              '';
            };

            secretPath = mkOption {
              type = types.path;
              description = ''
                Path to secret key value.
              '';
            };
          };
        });
      };
      description = ''
        Supported OpenID Connect clients.
      '';
    };
  };

  config = mkIf cfg.enable (let
    stateDirectory = "/var/lib/authelia-main";
    usersConfig = "${stateDirectory}/users.yaml";
    clientsConfig = "${stateDirectory}/clients.yaml";
  in {
    assertions = [
      {
        assertion = cfg.users != {};
        message = ''
          At least one configured user is required to use Authelia.
        '';
      }
    ];

    services.authelia.instances.main = {
      enable = true;

      secrets = {
        inherit (cfg) jwtSecretFile oidcIssuerPrivateKeyFile storageEncryptionKeyFile;
      };

      settings = {
        theme = "dark";

        server = {
          inherit (cfg) host port;
        };

        session = {
          inherit (cfg) domain;
        };

        authentication_backend = {
          file.path = usersConfig;
          password_reset.disable = true;
        };

        storage.local.path = "${stateDirectory}/db.sqlite3";
        notifier.filesystem.filename = "${stateDirectory}/notifications.txt";

        access_control.default_policy = "two_factor";

        default_2fa_method = "webauthn";
        webauthn = {
          attestation_conveyance_preference = "none";
          user_verification = "discouraged";
        };
      };

      settingsFiles = optional (cfg.oidc.clients != {}) clientsConfig;
    };

    systemd.services.authelia-main.preStart = let
      yamlFormat = pkgs.formats.yaml {};

      usersPlaceholder = yamlFormat.generate "users" {
        users =
          mapAttrs (user: {
            displayname,
            email,
            ...
          }: {
            inherit displayname email;

            disabled = false;
            password = "^${user}Password^";
          })
          cfg.users;
      };

      usersReplaceSecretInvocation = concatStringsSep "\n" (
        mapAttrsToList
        (user: {passwordFile, ...}: ''
          ${getExe pkgs.replace-secret} \
            "^${user}Password^" \
            "${passwordFile}" \
            ${usersConfig}
        '')
        cfg.users
      );

      clientsPlaceholder = yamlFormat.generate "clients" (
        optionalAttrs (cfg.oidc.clients != {}) {
          identity_providers.oidc.clients =
            mapAttrsToList
            (id: {redirectUris, ...}: {
              inherit id;

              consent_mode = "implicit";
              redirect_uris = redirectUris;
              secret = "^${id}Secret^";
            })
            cfg.oidc.clients;
        }
      );

      clientsReplaceSecretInvocation = concatStringsSep "\n" (
        mapAttrsToList
        (id: {secretPath, ...}: ''
          autheliaOutput=$(
            ${getExe config.services.authelia.instances.main.package} crypto hash generate argon2 \
              --password $(cat ${secretPath})
          )
          digest=$(echo $autheliaOutput | cut -d " " -f 2 | tr -d '\n')
          sed -i "s|\^${id}Secret\^|$digest|" ${clientsConfig}
        '')
        cfg.oidc.clients
      );
    in ''
      # Users config file generation
      cp ${usersPlaceholder} ${usersConfig}
      chmod 0600 ${usersConfig}
      ${usersReplaceSecretInvocation}

      # Clients config file generation
      cp ${clientsPlaceholder} ${clientsConfig}
      chmod 0600 ${clientsConfig}
      ${clientsReplaceSecretInvocation}
    '';

    modulo = {
      headless.nginx.upstreams.authelia = "${cfg.host}:${builtins.toString cfg.port}";

      impermanence.directories = [
        {
          directory = "/var/lib/authelia-main";
          mode = "0700";
          user = "authelia-main";
          group = "authelia-main";
        }
      ];
    };
  });
}
