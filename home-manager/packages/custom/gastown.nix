# Gastown (gt) — multi-agent orchestration for AI coding agents.
{ pkgs, ... }:

{
  home.packages = [
    (pkgs.stdenv.mkDerivation rec {
      pname = "gastown";
      version = "0.7.0";

      src = pkgs.fetchurl {
        url = "https://github.com/steveyegge/gastown/releases/download/v${version}/gastown_${version}_linux_amd64.tar.gz";
        sha256 = "e5e852faef20f442215cb90caa8661cbb013c20565fed2510a1c8732c35cbc33";
      };

      sourceRoot = ".";

      installPhase = ''
        install -Dm755 gt $out/bin/gt
      '';

      meta = with pkgs.lib; {
        description = "Multi-agent workspace manager for AI coding agents";
        homepage = "https://github.com/steveyegge/gastown";
        license = licenses.asl20;
        platforms = [ "x86_64-linux" ];
        mainProgram = "gt";
      };
    })
  ];
}
