# Beads (bd) — git-backed issue tracking for AI coding agents.
{ pkgs, ... }:

let
  beadsMeta = with pkgs.lib; {
    description = "Git-backed graph issue tracker for AI coding agents";
    homepage = "https://github.com/steveyegge/beads";
    license = licenses.asl20;
    platforms = [ "x86_64-linux" ];
    mainProgram = "bd";
  };
in

{
  home.packages = [
    (pkgs.stdenv.mkDerivation rec {
      pname = "beads";
      version = "0.56.1";

      src = pkgs.fetchurl {
        url = "https://github.com/steveyegge/beads/releases/download/v${version}/beads_${version}_linux_amd64.tar.gz";
        sha256 = "4f9f6cc44465a11613ff529009901eaaf841c6b1f91c15e002b0ecda2015a15c";
      };

      sourceRoot = ".";

      installPhase = ''
        install -Dm755 bd $out/bin/bd
      '';

      meta = beadsMeta;
    })
  ];
}
