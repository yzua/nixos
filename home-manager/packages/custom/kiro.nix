# Kiro CLI — agentic workflows in the terminal.

{ pkgs, ... }:

let
  kiroCli = pkgs.stdenvNoCC.mkDerivation rec {
    pname = "kiro-cli";
    version = "1.29.6";

    src = pkgs.fetchurl {
      url = "https://prod.download.cli.kiro.dev/stable/${version}/kirocli-x86_64-linux.tar.xz";
      sha256 = "fdff585207cf5a259ac4e6563e69c12d81f03612b1be99cf7dc408ccfc48cb5f";
    };

    nativeBuildInputs = [
      pkgs.autoPatchelfHook
      pkgs.makeWrapper
    ];

    buildInputs = [ pkgs.stdenv.cc.cc.lib ];

    sourceRoot = ".";

    installPhase = ''
      runHook preInstall

      install -d "$out/bin" "$out/libexec/kiro-cli"
      cp -r kirocli/. "$out/libexec/kiro-cli/"

      install -m755 "$out/libexec/kiro-cli/bin/kiro-cli" "$out/bin/kiro-cli"
      install -m755 "$out/libexec/kiro-cli/bin/kiro-cli-chat" "$out/bin/kiro-cli-chat"
      install -m755 "$out/libexec/kiro-cli/bin/kiro-cli-term" "$out/bin/kiro-cli-term"

      makeWrapper "$out/bin/kiro-cli" "$out/bin/q" \
        --add-flags "--show-legacy-warning"
      makeWrapper "$out/bin/kiro-cli" "$out/bin/qchat" \
        --add-flags "--show-legacy-warning chat"

      runHook postInstall
    '';

    meta = with pkgs.lib; {
      description = "Kiro CLI for agentic workflows in the terminal";
      homepage = "https://kiro.dev/cli";
      license = licenses.amazonsl;
      sourceProvenance = with sourceTypes; [ binaryNativeCode ];
      platforms = [ "x86_64-linux" ];
      mainProgram = "kiro-cli";
    };
  };
in

{
  home.packages = [ kiroCli ];
}
