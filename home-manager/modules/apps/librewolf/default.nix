# LibreWolf browser with declarative baseline policies, multi-profile proxy setup, and extensions.
{
  pkgsStable,
  ...
}:
{
  home.file = {
    ".local/bin/librewolf-main" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        set -euo pipefail
        exec /run/current-system/sw/bin/librewolf \
          --new-instance \
          --name librewolf-main \
          --profile "$HOME/.librewolf/acffhfnf.default" \
          "$@"
      '';
    };

    ".local/bin/librewolf-i2pd" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        set -euo pipefail
        exec /run/current-system/sw/bin/librewolf \
          --new-instance \
          --name librewolf-i2pd \
          --profile "$HOME/.librewolf/i2pd.default" \
          "$@"
      '';
    };

    ".librewolf/acffhfnf.default/chrome/userChrome.css".source =
      ../../../../themes/librewolf-userChrome.css;
    ".librewolf/acffhfnf.default/chrome/userContent.css".source =
      ../../../../themes/librewolf-userContent.css;
    ".librewolf/i2pd.default/chrome/userChrome.css".source =
      ../../../../themes/librewolf-userChrome.css;
    ".librewolf/i2pd.default/chrome/userContent.css".source =
      ../../../../themes/librewolf-userContent.css;
  };

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
      ExtensionSettings = {
        # Declarative Firefox add-ons.
        # Enhanced GitHub
        "{72bd91c9-3dc5-40a8-9b10-dec633c0873f}" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/enhanced-github/latest.xpi";
        };
        # Octotree - GitHub code tree
        "jid1-Om7eJGwA1U8Akg@jetpack" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/octotree/latest.xpi";
        };
        # Refined GitHub
        "{a4c4eda4-fb84-4a84-b4a1-f7c1cbf2a1ad}" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/refined-github-/latest.xpi";
        };
        # SimpleLogin by Proton: Secure Email Aliases
        "addon@simplelogin" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/simplelogin/latest.xpi";
        };
        # Random User-Agent (Switcher)
        "{b43b974b-1d3a-4232-b226-eaa2ac6ebb69}" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/random_user_agent/latest.xpi";
        };
        # Privacy Badger
        "jid1-MnnxcxisBPnSXQ@jetpack" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/privacy-badger17/latest.xpi";
        };
        # KeePassXC-Browser
        "keepassxc-browser@keepassxc.org" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/keepassxc-browser/latest.xpi";
        };
        # Dark Reader
        "addon@darkreader.org" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/darkreader/latest.xpi";
        };
        # JSON Viewer
        "@jsonviewernickprogramm" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/json-viewer-nick/latest.xpi";
        };
        # Wappalyzer - Technology profiler
        "wappalyzer@crunchlabz.com" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/wappalyzer/latest.xpi";
        };
        # React Developer Tools
        "@react-devtools" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/react-devtools/latest.xpi";
        };
        # Return YouTube Dislike
        "{762f9885-5a13-4abd-9c77-433dcd38b8fd}" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/return-youtube-dislikes/latest.xpi";
        };
        # Unhook - Remove YouTube Recommended & Shorts
        "myallychou@gmail.com" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/youtube-recommended-videos/latest.xpi";
        };
        # Control Panel for Twitter
        "{5cce4ab5-3d47-41b9-af5e-8203eea05245}" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/control-panel-for-twitter/latest.xpi";
        };
        # SponsorBlock for YouTube - Skip Sponsorships
        "sponsorBlocker@ajay.app" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/sponsorblock/latest.xpi";
        };
        # Gruvbox Material Theme
        "{1e01c787-99d2-4826-86df-0003da8e88cd}" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/gruvbox-material-theme/latest.xpi";
        };
        # New Tab (shows your homepage)
        "{ffd1b628-42fb-4779-a7ad-569b801b85bc}" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/new-tab-shows-your-homepage/latest.xpi";
        };
        # Redirector (URL-based redirects, e.g. YouTube -> custom target)
        "redirector@einaregilsson.com" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/redirector/latest.xpi";
        };
        # Violentmonkey (userscript manager)
        "{aecec67f-0d10-4fa7-b7c7-609a2db280cf}" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/violentmonkey/latest.xpi";
        };
        # Stylus
        "{7a7a4a92-a2a0-41d1-9fd7-1e92480d612d}" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/styl-us/latest.xpi";
        };
        # Sidebery
        "{3c078156-979c-498b-8990-85f7987dd929}" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/sidebery/latest.xpi";
        };
      };
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
        # === Browser UX ===
        "app.update.auto" = false;
        "browser.shell.checkDefaultBrowser" = false;
        "browser.startup.homepage" = "http://127.0.0.1:8082/search";
        "browser.startup.page" = 1;
        "browser.newtabpage.enabled" = true;
        "browser.privatebrowsing.autostart" = false;
        "browser.compactmode.show" = true;
        "browser.uidensity" = 1; # Compact UI density
        "browser.toolbars.bookmarks.visibility" = "newtab";
        "browser.tabs.loadInBackground" = true;
        "browser.tabs.warnOnClose" = false;
        "browser.tabs.closeWindowWithLastTab" = false;

        # === Theme ===
        "extensions.activeThemeID" = "{1e01c787-99d2-4826-86df-0003da8e88cd}";
        "layout.css.prefers-color-scheme.content-override" = 0; # Prefer dark
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        "layout.css.moz-document.content.enabled" = true;

        # === Sidebar ===
        # Keep Firefox native sidebar disabled when using Sidebery.
        "sidebar.revamp" = false;
        "sidebar.verticalTabs" = false;
        "sidebar.visibility" = "hide-sidebar";

        "media.peerconnection.enabled" = false;

        "network.cookie.lifetimePolicy" = 0;
        "privacy.clearOnShutdown.cookies" = false;
        "privacy.clearOnShutdown.offlineApps" = false;
        "privacy.clearOnShutdown.history" = false;
        "privacy.clearOnShutdown.cache" = false;
        "privacy.sanitize.sanitizeOnShutdown" = false;

        "network.proxy.type" = 1;
        "network.proxy.socks" = "nl-ams-wg-socks5-001.relays.mullvad.net";
        "network.proxy.socks_port" = 1080;
        "network.proxy.socks_version" = 5;
        "network.proxy.socks_remote_dns" = true;
        "network.protocol-handler.external.ytmpv" = true;
        "network.protocol-handler.expose.ytmpv" = false;
        "network.protocol-handler.warn-external.ytmpv" = false;
      };
    };

    profiles.i2pd = {
      id = 1;
      isDefault = false;
      path = "i2pd.default";
      settings = {
        "app.update.auto" = false;
        "browser.shell.checkDefaultBrowser" = false;
        "browser.startup.homepage" = "about:blank";
        "browser.startup.page" = 1;
        "browser.newtabpage.enabled" = false;
        "browser.privatebrowsing.autostart" = false;

        "media.peerconnection.enabled" = false;

        "network.proxy.type" = 1;
        "network.proxy.socks" = "127.0.0.1";
        "network.proxy.socks_port" = 4447;
        "network.proxy.socks_version" = 5;
        "network.proxy.socks_remote_dns" = true;
        "network.protocol-handler.external.ytmpv" = true;
        "network.protocol-handler.expose.ytmpv" = false;
        "network.protocol-handler.warn-external.ytmpv" = false;

        "sidebar.revamp" = false;
        "sidebar.verticalTabs" = false;
        "sidebar.visibility" = "hide-sidebar";
        "extensions.activeThemeID" = "{1e01c787-99d2-4826-86df-0003da8e88cd}";
        "layout.css.moz-document.content.enabled" = true;
      };
    };
  };

  home.file.".librewolf/profiles.ini".force = true;
}
