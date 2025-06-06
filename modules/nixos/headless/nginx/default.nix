{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    attrNames
    concatMapStringsSep
    concatStringsSep
    filterAttrs
    hasAttr
    isString
    length
    mapAttrs
    mkIf
    mkOption
    optionalAttrs
    optionalString
    splitString
    sublist
    types
    ;

  cfg = config.modulo.headless.nginx;
in
{
  options.modulo.headless.nginx = {
    upstreams = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = ''
        Supported Nginx upstreams.
      '';
    };

    activatedUpstreams = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            listen = mkOption {
              type = types.enum [
                "global"
                "wireguard"
              ];
              default = "global";
              description = ''
                Address types to listen on:
                  * `global` - listen on all interfaces.
                  * `wireguard` - listen only on the WireGuard interface.
              '';
            };

            upstream = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = ''
                Upstream address.
              '';
            };

            redirect = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = ''
                Redirect URL.
              '';
            };

            ssl = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = ''
                SSL certificate source.
                When `null` and `listen` is `global` hostname will be determined
                using the second-level domain. TLS is always disabled when using WireGuard `listen`.
              '';
            };

            cors = {
              methods = mkOption {
                type = types.listOf types.str;
                default = [ ];
                description = ''
                  Allowed HTTP request methods.
                  Access-Control-Allow-Methods header is omitted when empty.
                '';
              };

              origin = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = ''
                  Allowed HTTP request origin.
                  Access-Control-Allow-Origin header is omitted when null.
                '';
              };

              headers = mkOption {
                type = types.listOf types.str;
                default = [ ];
                description = ''
                  Allowed HTTP headers.
                  Access-Control-Allow-Headers header is omitted when empty.
                '';
              };

              allowCredentials = mkOption {
                type = types.bool;
                default = false;
                description = ''
                  Controls credential exposure to scripts.
                '';
              };
            };
          };
        }
      );
      default = { };
      description = ''
        Activated Nginx upstreams.
      '';
    };

    limits = {
      connectionCount = mkOption {
        type = types.int;
        default = 10240;
        description = ''
          Simultaneous connections limit per worker thread.
        '';
      };

      headerSize = mkOption {
        type = types.str;
        default = "32k";
        description = ''
          Request headers size limit.
          This value also affects large header buffers.
        '';
      };

      bodySize = mkOption {
        type = types.str;
        default = "128k";
        description = ''
          Request body size limit.
        '';
      };

      timeout = mkOption {
        type = types.str;
        default = "15s";
        description = ''
          General connection timeout, which applies to different configuration options.
        '';
      };
    };
  };

  config = mkIf (cfg.activatedUpstreams != { }) {
    assertions =
      let
        mkActivatedUpstreamAssertion = f: (filterAttrs f cfg.activatedUpstreams) == { };
      in
      [
        {
          assertion =
            let
              upstreamed = filterAttrs (_: { upstream, ... }: upstream != null) cfg.activatedUpstreams;

              activatedUpstreams = filterAttrs (_: { upstream, ... }: hasAttr upstream cfg.upstreams) upstreamed;
            in
            (attrNames activatedUpstreams) == (attrNames upstreamed);

          message = ''
            Only upstreams defined via config.modulo.headless.nginx.upstreams can be activated
            via config.modulo.headless.nginx.activatedUpstreams.
          '';
        }
        {
          assertion = mkActivatedUpstreamAssertion (
            _:
            {
              upstream,
              redirect,
              ...
            }:
            (upstream == null && redirect == null) || (upstream != null && redirect != null)
          );

          message = ''
            All activated upstreams must have either upstream reference or
            redirect URL set.
          '';
        }
        {
          assertion = mkActivatedUpstreamAssertion (
            _: { cors, ... }: (cors.origin == "*") && cors.allowCredentials
          );

          message = ''
            Wildcard origin and allowCredentials cannot be used together per https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Allow-Credentials.
          '';
        }
        {
          assertion = mkActivatedUpstreamAssertion (
            _: { listen, ... }: listen == "wireguard" && config.modulo.networking.wireguard.addresses == [ ]
          );

          message = ''
            WireGuard upstreams require an active WireGuard configuration.
          '';
        }
      ];

    services.nginx =
      let
        inherit (cfg) limits;
      in
      {
        enable = true;

        recommendedOptimisation = true;
        recommendedTlsSettings = true;
        recommendedGzipSettings = true;
        recommendedProxySettings = true;

        serverTokens = false;

        appendConfig = ''
          worker_processes auto;
          worker_rlimit_nofile ${toString (limits.connectionCount * 2)};
        '';

        eventsConfig = ''
          worker_connections ${toString limits.connectionCount};
        '';

        clientMaxBodySize = limits.bodySize;
        proxyTimeout = limits.timeout;
        commonHttpConfig = ''
          access_log off;

          reset_timedout_connection on;

          client_body_buffer_size ${limits.bodySize};
          client_header_buffer_size ${limits.headerSize};
          large_client_header_buffers 2 ${limits.headerSize};

          client_body_timeout ${limits.timeout};
          client_header_timeout ${limits.timeout};
          send_timeout ${limits.timeout};
        '';

        upstreams = mapAttrs (_: endpoint: {
          servers.${endpoint} = { };
        }) cfg.upstreams;

        virtualHosts =
          (mapAttrs (
            name:
            {
              listen,
              upstream,
              redirect,
              ssl,
              cors,
            }:
            {
              listenAddresses = mkIf (listen == "wireguard") (
                map (a: "[${a}]") config.modulo.networking.wireguard.addresses
              );

              locations =
                let
                  extraConfig =
                    let
                      allowedMethods = cors.methods ++ [ "OPTIONS" ];

                      sharedConfig = ''
                        add_header 'Access-Control-Allow-Methods' '${concatStringsSep "," allowedMethods}' always;
                        ${optionalString (
                          cors.headers != [ ]
                        ) "add_header 'Access-Control-Allow-Headers' '${concatStringsSep "," cors.headers}' always;"}
                        ${optionalString (
                          cors.origin != null
                        ) "add_header 'Access-Control-Allow-Origin' '${cors.origin}' always;"}
                        ${optionalString cors.allowCredentials "add_header 'Access-Control-Allow-Credentials' 'true' always;"}
                      '';

                      optionsConfig = ''
                        add_header 'Access-Control-Max-Age' 2592000;
                        add_header 'Content-Length' 0;
                        add_header 'Content-Type' 'text/plain; charset=utf-8';
                        return 204;
                      '';

                      # Requests with OPTIONS method have to be handled even if the CORS configuration is empty
                      mkMethodConfig = method: ''
                        if ($request_method = '${method}') {
                          ${sharedConfig}
                          ${optionalString (method == "OPTIONS") optionsConfig}
                        }
                      '';

                      proxyHide = optionalString (upstream != null) ''
                        proxy_hide_header Access-Control-Allow-Methods;
                        proxy_hide_header Access-Control-Allow-Headers;
                        proxy_hide_header Access-Control-Allow-Origin;
                        proxy_hide_header Access-Control-Allow-Credentials;
                      '';
                    in
                    ''
                      ${proxyHide}
                      ${concatMapStringsSep "\n" mkMethodConfig allowedMethods}
                    '';

                  proxyLocation = {
                    inherit extraConfig;

                    proxyPass = "http://${upstream}";
                    proxyWebsockets = true;
                  };

                  redirectLocation = {
                    inherit extraConfig;

                    return = "302 ${redirect}$request_uri";
                  };
                in
                {
                  "/" = if (upstream != null) then proxyLocation else redirectLocation;
                };
            }
            // (optionalAttrs (listen == "global") {
              useACMEHost =
                let
                  components = splitString "." name;
                  total = length components;
                in
                if isString ssl then ssl else concatStringsSep "." (sublist (total - 2) total components);

              forceSSL = true;
              kTLS = true;
            })
          ) cfg.activatedUpstreams)
          // {
            "_" = {
              default = true;
              rejectSSL = true;
              extraConfig = ''
                return 400;
              '';
            };
          };
      };

    users.users.nginx.extraGroups = [ config.security.acme.defaults.group ];
  };
}
