# Cursor Agent — terminal agent CLI from Cursor Labs.

{ pkgs, ... }:

let
  cursorAgent = pkgs.stdenvNoCC.mkDerivation rec {
    pname = "cursor-agent";
    version = "2026.04.08-a41fba1";

    src = pkgs.fetchurl {
      url = "https://downloads.cursor.com/lab/${version}/linux/x64/agent-cli-package.tar.gz";
      sha256 = "sha256-zHNiy5I61cN6BpfRv1TozdRk+2R/RNxIanCPkwqdfZE=";
    };

    nativeBuildInputs = [
      pkgs.autoPatchelfHook
      pkgs.makeWrapper
    ];

    buildInputs = [ pkgs.stdenv.cc.cc.lib ];

    sourceRoot = ".";

    installPhase = ''
      runHook preInstall

      install -d "$out/bin" "$out/libexec/cursor-agent"
      cp -r dist-package/. "$out/libexec/cursor-agent/"

      ln -s "$out/libexec/cursor-agent/cursor-agent" "$out/bin/cursor-agent"
      ln -s "$out/libexec/cursor-agent/cursor-agent" "$out/bin/agent"

      runHook postInstall
    '';

    meta = with pkgs.lib; {
      description = "Cursor terminal agent CLI";
      homepage = "https://cursor.com";
      license = licenses.unfree;
      sourceProvenance = with sourceTypes; [ binaryNativeCode ];
      platforms = [ "x86_64-linux" ];
      mainProgram = "agent";
    };
  };
in

{
  home.packages = [ cursorAgent ];
}
