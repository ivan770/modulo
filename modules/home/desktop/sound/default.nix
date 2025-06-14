{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  inherit (pkgs.modulo) rnnoise;

  cfg = config.modulo.desktop.sound;
  soundEnabled = osConfig.modulo.desktop.sound.enable;
in
{
  options.modulo.desktop.sound = {
    noiseCancellation = {
      enable = mkEnableOption "PipeWire noise cancellation";

      output = mkOption {
        type = types.enum [
          "mono"
          "stereo"
        ];
        default = "mono";
        description = ''
          Output type.
        '';
      };

      threshold = mkOption {
        type = types.numbers.between 0 100;
        default = 85;
        description = ''
          Voice probability threshold.
        '';
      };

      gracePeriod = mkOption {
        type = types.numbers.positive;
        default = 200;
        description = ''
          For how long (in milliseconds) to keep the output after voice detection.
        '';
      };
    };
  };

  config = mkIf (soundEnabled && cfg.noiseCancellation.enable) {
    xdg.configFile."pipewire/pipewire.conf.d/50-noise-cancellation.conf".text = builtins.toJSON {
      "context.modules" = [
        {
          name = "libpipewire-module-filter-chain";
          args = {
            "node.name" = "noise-cancellation";
            "node.description" = "Noise cancelling source";
            "media.name" = "Noise cancelling source";
            "filter.graph" = {
              nodes = [
                {
                  type = "ladspa";
                  name = "rnnoise";
                  plugin = "${rnnoise}/lib/ladspa/librnnoise_ladspa.so";
                  label = "noise_suppressor_${cfg.noiseCancellation.output}";
                  control = {
                    "VAD Threshold (%)" = cfg.noiseCancellation.threshold;
                    "VAD Grace Period (ms)" = cfg.noiseCancellation.gracePeriod;
                    "Retroactive VAD Grace (ms)" = 0;
                  };
                }
              ];
            };
            "capture.props" = {
              "node.name" = "capture.rnnoise_source";
              "node.passive" = true;
              "audio.rate" = 48000;
            };
            "playback.props" = {
              "node.name" = "rnnoise_source";
              "media.class" = "Audio/Source";
              "audio.rate" = 48000;
            };
          };
        }
      ];
    };
  };
}
