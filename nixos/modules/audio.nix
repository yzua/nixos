# PipeWire audio stack (ALSA, PulseAudio compat, JACK, RNNoise).
{ pkgs, ... }:

let
  rnnoise = pkgs.rnnoise-plugin;
in
{
  security.rtkit.enable = true;

  services = {
    pulseaudio.enable = false;

    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;

      # RNNoise mic noise cancellation for video calls
      extraConfig.pipewire = {
        "99-rnnoise" = {
          "context.modules" = [
            {
              name = "libpipewire-module-filter-chain";
              args = {
                "node.description" = "Noise Cancelling Source";
                "media.name" = "Noise Cancelling Source";
                "filter.graph" = {
                  nodes = [
                    {
                      type = "ladspa";
                      name = "rnnoise";
                      plugin = "${rnnoise}/lib/ladspa/librnnoise_ladspa.so";
                      label = "noise_suppressor_stereo";
                      control = {
                        "VAD Threshold (%)" = 50.0;
                      };
                    }
                  ];
                };
                "capture.props" = {
                  "node.name" = "effect_input.rnnoise";
                  "node.passive" = true;
                };
                "playback.props" = {
                  "node.name" = "effect_output.rnnoise";
                  "media.class" = "Audio/Source";
                };
              };
            }
          ];
        };
      };
    };
  };

  environment.systemPackages = [ pkgs.rnnoise-plugin ];
}
