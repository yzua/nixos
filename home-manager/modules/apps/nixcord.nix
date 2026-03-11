# Discord (Vesktop + Vencord) declarative configuration.

{ inputs, ... }:

let
  mkEnabledPlugins =
    names:
    builtins.listToAttrs (
      map (name: {
        inherit name;
        value.enable = true;
      }) names
    );

  uiUxPlugins = [
    "alwaysTrust"
    "betterFolders"
    "betterRoleContext"
    "crashHandler"
    "experiments"
    "fakeNitro"
    "fixSpotifyEmbeds"
    "imageZoom"
    "memberCount"
    "permissionsViewer"
    "PinDMs"
    "quickMention"
    "readAllNotificationsButton"
    "revealAllSpoilers"
    "serverListIndicators"
    "showHiddenChannels"
    "spotifyControls"
    "themeAttributes"
    "typingIndicator"
    "voiceMessages"
    "volumeBooster"
    "webContextMenus"
    "whoReacted"
  ];

  privacyPlugins = [
    "anonymiseFileNames"
    "ClearURLs"
    "silentTyping"
  ];

  loggingNotificationPlugins = [
    "messageLogger"
    "relationshipNotifier"
  ];
in

{
  imports = [ inputs.nixcord.homeModules.nixcord ];

  programs.nixcord = {
    enable = true;

    discord.enable = false; # Vesktop replaces bare Discord
    vesktop.enable = true;

    config = {
      useQuickCss = true;
      frameless = true;

      # Gruvbox dark theme (shvedes/discord-gruvbox — maintained for latest Discord UI)
      themeLinks = [
        "https://raw.githubusercontent.com/shvedes/discord-gruvbox/main/gruvbox-dark.theme.css"
      ];

      plugins =
        mkEnabledPlugins uiUxPlugins
        // mkEnabledPlugins privacyPlugins
        // mkEnabledPlugins loggingNotificationPlugins;
    };
  };
}
