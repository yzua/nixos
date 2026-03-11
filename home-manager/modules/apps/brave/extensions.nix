# Brave extensions captured from current local profile.
{
  programs.brave.extensions =
    let
      githubExtensions = [
        "anlikcnbgdeidpacdbdljnabclhahhmd" # Enhanced GitHub
        "bkhaagjahfmjljalopjnoealnfndnagc" # Octotree - GitHub code tree
        "hlepfoohegkhhmjieoechaddaejaokhf" # Refined GitHub
      ];

      privacySecurityExtensions = [
        "dphilobhebphkdjbpfohgikllaljmgbn" # SimpleLogin by Proton: Secure Email Aliases
        "einpaelgookohagofgnnkcfjbkkgepnp" # Random User-Agent (Switcher)
        "nomnklagbgmgghhjidfhnoelnjfndfpd" # Canvas Blocker - Fingerprint Protect
        "pkehgijcmpdhfbdbbnkijodmdjhbjlgp" # Privacy Badger
        "oboonakemofpalcgghocfoadofidjkkk" # KeePassXC-Browser
      ];

      webDevExtensions = [
        "eimadpbcbfnmbkopoojfekhnkhdbieeh" # Dark Reader
        "fcoeoabgfenejglbffodgkkbkcdhcgfn" # Claude
        "gbmdgpbipfallnflgajpaliibnhdgobh" # JSON Viewer
        "gppongmhjkpfnbhagpmjfkannfbllamg" # Wappalyzer - Technology profiler
        "fmkadmapgofadopljbjfkapdkoienihi" # React Developer Tools
      ];

      youtubeSocialExtensions = [
        "gebbhagfogifgggkldgodflihgfeippi" # Return YouTube Dislike
        "khncfooichmfjbepaaaebmommgaepoid" # Unhook - Remove YouTube Recommended & Shorts
        "kpmjjdhbcfebfjgdnpjagcndoelnidfj" # Control Panel for Twitter
        "mnjggcdmjocbbbhaepdhchncahnbgone" # SponsorBlock for YouTube - Skip Sponsorships
      ];
    in
    githubExtensions ++ privacySecurityExtensions ++ webDevExtensions ++ youtubeSocialExtensions;
}
