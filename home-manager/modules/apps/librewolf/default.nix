# LibreWolf browser with declarative baseline policies and proxy settings.
{
  pkgsStable,
  ...
}:
{
  programs.librewolf = {
    enable = true;
    package = pkgsStable.librewolf;

    policies = {
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      DisablePocket = true;
      DisableFirefoxAccounts = true;
      DontCheckDefaultBrowser = true;
      OfferToSaveLogins = false;
      PasswordManagerEnabled = false;
      UserMessaging = {
        ExtensionRecommendations = false;
        SkipOnboarding = true;
      };
    };

    profiles.default = {
      id = 0;
      isDefault = true;
      path = "acffhfnf.default";
      settings = {
        "app.update.auto" = false;
        "browser.shell.checkDefaultBrowser" = false;
        "browser.startup.homepage" = "about:home";
        "browser.newtabpage.enabled" = true;
        "browser.privatebrowsing.autostart" = false;

        "media.peerconnection.enabled" = false;

        "network.cookie.lifetimePolicy" = 0;
        "privacy.clearOnShutdown.cookies" = false;
        "privacy.clearOnShutdown.offlineApps" = false;
        "privacy.clearOnShutdown.history" = false;
        "privacy.clearOnShutdown.cache" = false;
        "privacy.sanitize.sanitizeOnShutdown" = false;

        "network.proxy.type" = 1;
        "network.proxy.socks" = "se-mma-wg-socks5-004.relays.mullvad.net";
        "network.proxy.socks_port" = 1080;
        "network.proxy.socks_version" = 5;
        "network.proxy.socks_remote_dns" = true;
      };
    };
  };

  home.file.".librewolf/profiles.ini".force = true;
}
