{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    attrNames
    concatStringsSep
    genAttrs
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
in
{
  options.modulo.headless.authelia = {
    enable = mkEnableOption "Authelia authentication server";

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
      type = types.attrsOf (
        types.submodule {
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
          };
        }
      );
      description = ''
        Supported users.
      '';
    };

    oidc = {
      clients = mkOption {
        type = types.attrsOf (
          types.submodule {
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
          }
        );
      };
      description = ''
        Supported OpenID Connect clients.
      '';
    };
  };

  config = mkIf cfg.enable (
    let
      stateDirectory = "/var/lib/authelia-main";
      usersConfig = "${stateDirectory}/users.yaml";
      clientsConfig = "${stateDirectory}/clients.yaml";
    in
    {
      assertions = [
        {
          assertion = cfg.users != { };
          message = ''
            At least one configured user is required to use Authelia.
          '';
        }
      ];

      services.authelia.instances.main = {
        enable = true;

        secrets = genAttrs [ "jwtSecretFile" "oidcIssuerPrivateKeyFile" "storageEncryptionKeyFile" ] (
          name: config.modulo.secrets.values."authelia/${name}"
        );

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

        settingsFiles = optional (cfg.oidc.clients != { }) clientsConfig;
      };

      systemd.services.authelia-main.preStart =
        let
          yamlFormat = pkgs.formats.yaml { };

          usersPlaceholder = yamlFormat.generate "users" {
            users = mapAttrs (
              user:
              {
                displayname,
                email,
                ...
              }:
              {
                inherit displayname email;

                disabled = false;
                password = "^${user}Password^";
              }
            ) cfg.users;
          };

          usersReplaceSecretInvocation = concatStringsSep "\n" (
            mapAttrsToList (user: _: ''
              ${getExe pkgs.replace-secret} \
                "^${user}Password^" \
                "${config.modulo.secrets.values."authelia/users/${user}"}" \
                ${usersConfig}
            '') cfg.users
          );

          clientsPlaceholder = yamlFormat.generate "clients" (
            optionalAttrs (cfg.oidc.clients != { }) {
              identity_providers.oidc.clients = mapAttrsToList (
                id:
                { redirectUris, ... }:
                {
                  inherit id;

                  consent_mode = "implicit";
                  redirect_uris = redirectUris;
                  secret = "^${id}Secret^";
                }
              ) cfg.oidc.clients;
            }
          );

          clientsReplaceSecretInvocation = concatStringsSep "\n" (
            mapAttrsToList (
              id:
              { secretPath, ... }:
              ''
                autheliaOutput=$(
                  ${getExe config.services.authelia.instances.main.package} crypto hash generate argon2 \
                    --password $(cat ${secretPath})
                )
                digest=$(echo $autheliaOutput | cut -d " " -f 2 | tr -d '\n')
                sed -i "s|\^${id}Secret\^|$digest|" ${clientsConfig}
              ''
            ) cfg.oidc.clients
          );
        in
        ''
          cp ${usersPlaceholder} ${usersConfig}
          chmod 0600 ${usersConfig}
          ${usersReplaceSecretInvocation}

          cp ${clientsPlaceholder} ${clientsConfig}
          chmod 0600 ${clientsConfig}
          ${clientsReplaceSecretInvocation}
        '';

      modulo = {
        headless.nginx.upstreams.authelia = "${cfg.host}:${toString cfg.port}";

        impermanence.directories = [
          {
            directory = "/var/lib/authelia-main";
            mode = "0700";
            user = "authelia-main";
            group = "authelia-main";
          }
        ];

        secrets.applications =
          genAttrs
            (
              [
                "authelia/jwtSecretFile"
                "authelia/oidcIssuerPrivateKeyFile"
                "authelia/storageEncryptionKeyFile"
              ]
              ++ map (user: "authelia/users/${user}") (attrNames cfg.users)
            )
            (_: {
              owner = config.services.authelia.instances.main.user;
            });
      };
    }
  );
}
