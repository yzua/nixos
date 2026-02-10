# Chromium browser, Puppeteer dependencies, and privacy flags.
{ pkgs, ... }:

{
  environment = {
    systemPackages = with pkgs; [
      ungoogled-chromium
      # Xvfb still needed on Wayland for headless browser testing
      xorg.xvfb
      xorg.xauth
    ];

    variables = {
      CHROME_DEVEL_SANDBOX = "${pkgs.ungoogled-chromium}/bin/chrome-devel-sandbox";
      PUPPETEER_HEADLESS = "new";
      # ELECTRON_OZONE_PLATFORM_HINT is set in niri/main.nix
      # H-03: --metrics-recording-only does NOT disable telemetry — replaced with proper flags
      CHROMIUM_FLAGS = "--disable-background-networking --disable-client-side-phishing-detection --disable-default-apps --disable-extensions --disable-sync --no-first-run --no-default-browser-check --disable-breakpad --disable-domain-reliability --disable-features=MediaRouter";
    };
  };
}
