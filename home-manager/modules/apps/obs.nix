# OBS Studio configuration with CUDA and essential plugins.

{ pkgs, ... }:

{
  programs.obs-studio = {
    enable = true;

    package = pkgs.obs-studio.override { cudaSupport = true; };

    plugins = with pkgs.obs-studio-plugins; [
      input-overlay # Display keyboard/mouse input
      wlrobs # Wayland screen capture
      obs-backgroundremoval # AI background removal
      obs-pipewire-audio-capture # PipeWire audio capture
      obs-vkcapture # Vulkan/OpenGL game capture
      obs-gstreamer # GStreamer integration for more sources
      obs-vaapi # VA-API hardware encoding (AMD/Intel)
      obs-move-transition # Smooth animated transitions between scenes
      obs-shaderfilter # Custom shader effects
      obs-source-record # Record individual sources separately
      advanced-scene-switcher # Automate scene switching
    ];
  };
}
