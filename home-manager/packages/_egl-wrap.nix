# Helper for wrapping GUI binaries with Mesa EGL vendor override.
{ pkgs }:

let
  mesaEglVendorFile = "/run/opengl-driver/share/glvnd/egl_vendor.d/50_mesa.json";
in
{
  inherit mesaEglVendorFile;

  wrapWithMesaEgl =
    name: pkg:
    pkgs.symlinkJoin {
      inherit name;
      paths = [ pkg ];
      buildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/${name} \
          --set __EGL_VENDOR_LIBRARY_FILENAMES ${mesaEglVendorFile}
      '';
    };
}
