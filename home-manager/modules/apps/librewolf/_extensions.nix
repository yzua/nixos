# LibreWolf extension policies — force-installed extensions with AMO URLs.

let
  mkExtension = id: install_url: {
    ${id} = {
      inherit installation_mode install_url;
    };
  };
  installation_mode = "force_installed";

  extensions = [
    (mkExtension "{72bd91c9-3dc5-40a8-9b10-dec633c0873f}" "https://addons.mozilla.org/firefox/downloads/latest/enhanced-github/latest.xpi")
    (mkExtension "jid1-Om7eJGwA1U8Akg@jetpack" "https://addons.mozilla.org/firefox/downloads/latest/octotree/latest.xpi")
    (mkExtension "{a4c4eda4-fb84-4a84-b4a1-f7c1cbf2a1ad}" "https://addons.mozilla.org/firefox/downloads/latest/refined-github-/latest.xpi")
    (mkExtension "addon@simplelogin" "https://addons.mozilla.org/firefox/downloads/latest/simplelogin/latest.xpi")
    (mkExtension "{b43b974b-1d3a-4232-b226-eaa2ac6ebb69}" "https://addons.mozilla.org/firefox/downloads/latest/random_user_agent/latest.xpi")
    (mkExtension "jid1-MnnxcxisBPnSXQ@jetpack" "https://addons.mozilla.org/firefox/downloads/latest/privacy-badger17/latest.xpi")
    (mkExtension "keepassxc-browser@keepassxc.org" "https://addons.mozilla.org/firefox/downloads/latest/keepassxc-browser/latest.xpi")
    (mkExtension "addon@darkreader.org" "https://addons.mozilla.org/firefox/downloads/latest/darkreader/latest.xpi")
    (mkExtension "@jsonviewernickprogramm" "https://addons.mozilla.org/firefox/downloads/latest/json-viewer-nick/latest.xpi")
    (mkExtension "wappalyzer@crunchlabz.com" "https://addons.mozilla.org/firefox/downloads/latest/wappalyzer/latest.xpi")
    (mkExtension "@react-devtools" "https://addons.mozilla.org/firefox/downloads/latest/react-devtools/latest.xpi")
    (mkExtension "{762f9885-5a13-4abd-9c77-433dcd38b8fd}" "https://addons.mozilla.org/firefox/downloads/latest/return-youtube-dislikes/latest.xpi")
    (mkExtension "myallychou@gmail.com" "https://addons.mozilla.org/firefox/downloads/latest/youtube-recommended-videos/latest.xpi")
    (mkExtension "{5cce4ab5-3d47-41b9-af5e-8203eea05245}" "https://addons.mozilla.org/firefox/downloads/latest/control-panel-for-twitter/latest.xpi")
    (mkExtension "sponsorBlocker@ajay.app" "https://addons.mozilla.org/firefox/downloads/latest/sponsorblock/latest.xpi")
    (mkExtension "{1e01c787-99d2-4826-86df-0003da8e88cd}" "https://addons.mozilla.org/firefox/downloads/latest/gruvbox-material-theme/latest.xpi")
    (mkExtension "{ffd1b628-42fb-4779-a7ad-569b801b85bc}" "https://addons.mozilla.org/firefox/downloads/latest/new-tab-shows-your-homepage/latest.xpi")
    (mkExtension "redirector@einaregilsson.com" "https://addons.mozilla.org/firefox/downloads/latest/redirector/latest.xpi")
    (mkExtension "{aecec67f-0d10-4fa7-b7c7-609a2db280cf}" "https://addons.mozilla.org/firefox/downloads/latest/violentmonkey/latest.xpi")
    (mkExtension "{7a7a4a92-a2a0-41d1-9fd7-1e92480d612d}" "https://addons.mozilla.org/firefox/downloads/latest/styl-us/latest.xpi")
    (mkExtension "{3c078156-979c-498b-8990-85f7987dd929}" "https://addons.mozilla.org/firefox/downloads/latest/sidebery/latest.xpi")
  ];
in
{
  ExtensionSettings = builtins.foldl' (acc: ext: acc // ext) { } extensions;
}
