# Discord (Vesktop + Vencord) declarative configuration.

{ inputs, ... }:

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

      plugins = {
        # === UI / UX ===
        alwaysTrust.enable = true;
        betterFolders.enable = true;
        betterRoleContext.enable = true;
        crashHandler.enable = true;
        experiments.enable = true;
        fakeNitro.enable = true;
        fixSpotifyEmbeds.enable = true;
        imageZoom.enable = true;
        memberCount.enable = true;
        permissionsViewer.enable = true;
        PinDMs.enable = true;
        quickMention.enable = true;
        readAllNotificationsButton.enable = true;
        revealAllSpoilers.enable = true;
        serverListIndicators.enable = true;
        showHiddenChannels.enable = true;
        spotifyControls.enable = true;
        themeAttributes.enable = true;
        typingIndicator.enable = true;
        voiceMessages.enable = true;
        volumeBooster.enable = true;
        webContextMenus.enable = true;
        whoReacted.enable = true;

        # === Privacy ===
        anonymiseFileNames.enable = true;
        ClearURLs.enable = true;
        silentTyping.enable = true;

        # === Logging / Notifications ===
        messageLogger.enable = true;
        relationshipNotifier.enable = true;
      };
    };
  };
}
