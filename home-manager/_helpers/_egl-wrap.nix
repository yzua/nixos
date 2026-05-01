# Helper for wrapping GUI binaries with Mesa EGL vendor override.

{
  pkgs,
  constants,
}:

let
  inherit (constants.paths) eglVendorFile;
in
{
  inherit eglVendorFile;

  wrapWithMesaEgl =
    name: pkg:
    pkgs.symlinkJoin {
      inherit name;
      paths = [ pkg ];
      buildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/${name} \
          --set __EGL_VENDOR_LIBRARY_FILENAMES ${eglVendorFile}
      '';
    };
}
