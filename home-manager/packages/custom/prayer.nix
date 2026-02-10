# Custom prayer times indicator for the desktop bar.
{ pkgsStable, ... }:

{
  home.packages = [
    (pkgsStable.rustPlatform.buildRustPackage {
      pname = "prayerbar";
      version = "unstable";

      src = pkgsStable.fetchFromGitHub {
        owner = "Onizuka893";
        repo = "prayerbar";
        rev = "337a83ac9c0e10360928c2e7859811e7bc1e3bfd";
        sha256 = "sha256-edDyN+shEkgc87yLH2sfpL8TjLn1+mwFCM0RlbQVzsg=";
      };

      cargoHash = "sha256-3DWCeQnLNINq6dsD0C5xRAZOnkAGRlxOfXwIOwCxy3c=";

      meta = with pkgsStable.lib; {
        description = "A simple prayer time indicator for Waybar";
        homepage = "https://github.com/Onizuka893/prayerbar";
        license = licenses.mit;
        platforms = [ pkgsStable.stdenv.hostPlatform.system ];
      };
    })
  ];
}
