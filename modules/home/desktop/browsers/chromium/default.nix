{
  config,
  lib,
  options,
  pkgs,
  ...
}:
let
  inherit (lib)
    concatStringsSep
    nameValuePair
    mapAttrs'
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  cfg = config.modulo.browsers.chromium;

  enabledFeatures = concatStringsSep "," (
    [
      # VA-API video acceleration
      "AcceleratedVideoDecodeLinuxGL"
      "AcceleratedVideoDecodeLinuxZeroCopyGL"
      "PlatformHEVCDecoderSupport"
      "UseMultiPlaneFormatForHardwareVideo"
      "VaapiVideoEncoder"
      "VaapiVideoDecoder"
      "VaapiIgnoreDriverChecks"

      # Vulkan
      "Vulkan"
      "DefaultANGLEVulkan"
      "VulkanFromANGLE"

      # Touchpad gestures
      "TouchpadOverscrollHistoryNavigation"

      # PipeWire camera support
      "WebRtcPipeWireCamera"
    ]
    ++ cfg.enabledFeatures
  );

  disabledFeatures = concatStringsSep "," [
    "UseChromeOSDirectVideoDecoder"
  ];

  flags = [
    "--enable-features=${enabledFeatures}"
    "--disable-features=${disabledFeatures}"

    # Vulkan
    "--use-gl=angle"
    "--use-angle=vulkan"

    # Wayland
    "--ozone-platform=wayland"
    "--gtk-version=4"

    # Offload stuff to GPU
    "--enable-gpu-rasterization"
    "--enable-zero-copy"
    "--disable-gpu-driver-bug-workaround"
    "--disable-gpu-driver-bug-workarounds"
    "--enable-accelerated-video-decode"
    "--ignore-gpu-blocklist"
  ]
  ++ cfg.commandLineArgs;

  writeJSON = config: pkgs.writeText "chromium.json" (builtins.toJSON config);

  extensions = pkgs.linkFarm "extensions" (
    mapAttrs' (
      id:
      {
        version,
        crx,
      }:
      nameValuePair "${id}.json" (writeJSON {
        external_version = version;
        external_crx = builtins.toString crx;
      })
    ) cfg.extensions
  );

  etcConfig = pkgs.linkFarm "chromium-config" {
    "policies/managed/policy.json" = writeJSON cfg.policies;

    initial_preferences = writeJSON cfg.initialPrefs;
  };

  appId = "org.chromium.Chromium";

  package =
    (config.modulo.desktop.sandbox.builder (
      { sloth, ... }:
      let
        chromiumConfigDir = sloth.concat' sloth.xdgConfigHome "/chromium";
      in
      {
        app.package = pkgs.ungoogled-chromium.override {
          commandLineArgs = concatStringsSep " " flags;
          enableWideVine = true;
        };

        flatpak.appId = appId;

        modulo = {
          audio.enable = true;
          gpu.enable = true;
          locale.enable = true;
          permissions = {
            document = true;
            mpris = "chromium";
          };
          syscallFilter.nestedSandboxing = true;
        };

        bubblewrap = {
          bind = {
            rw = [
              # Persistent data
              [
                (sloth.mkdir sloth.appDataDir)
                chromiumConfigDir
              ]

              # Temporary data
              # This directory is in the "bind.rw" section instead of
              # the "tmpfs" section because it has to be shared across multiple
              # Chromium instances.
              [
                (sloth.mkdir sloth.appCacheDir)
                (sloth.concat' sloth.xdgCacheHome "/chromium")
              ]
            ];

            ro = [
              [
                "${etcConfig}"
                "/etc/chromium"
              ]
              [
                "${extensions}"
                (sloth.concat' chromiumConfigDir "/External Extensions")
              ]
            ];
          };

          extraStorePaths = [
            etcConfig
            extensions
          ];
        };
      }
    )).config.env;
in
{
  options.modulo.browsers.chromium = {
    inherit (options.programs.chromium) commandLineArgs;

    enable = mkEnableOption "Chromium web browser";

    enabledFeatures = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = ''
        Features to append to the "enabled-features" flag.
      '';
    };

    extensions = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            version = mkOption {
              type = types.str;
              description = ''
                Extension version.
              '';
            };

            crx = mkOption {
              type = types.package;
              description = ''
                CRX file package.
              '';
            };
          };
        }
      );
      default = { };
      description = ''
        Chromium extensions to install.
      '';
    };

    policies = mkOption {
      type = types.attrs;
      default = { };
      description = ''
        Chromium enterprise policies to apply.
      '';
    };

    initialPrefs = mkOption {
      type = types.attrs;
      default = { };
      description = ''
        Chromium initial preferences to apply.
        These preferences apply only once during the browser first run.
      '';
    };
  };

  config = mkIf cfg.enable {
    programs.chromium = {
      inherit package;

      enable = true;
    };

    modulo.home-impermanence.directories = [
      {
        directory = ".var/app/${appId}/data";
        mode = "0700";
      }
    ];
  };
}
