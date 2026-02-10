# Nix flake for a C/C++ development environment.
{
  description = "C/C++ development template";

  inputs = {
    utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      nixpkgs,
      utils,
      ...
    }:

    utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            gcc
            cmake
            gnumake
            pkg-config
            clang-tools
            gdb
            valgrind
            cppcheck
          ];

          env = {
            CMAKE_EXPORT_COMPILE_COMMANDS = "ON";
          };

          shellHook = ''
            if [ ! -f CMakeLists.txt ] && [ ! -f Makefile ]; then
              echo "No build file found."
              echo "   cmake -B build .   # CMake project"
              echo "   touch Makefile     # Makefile project"
            else
              echo "C/C++ development environment ready!"
              echo "   cmake -B build && cmake --build build  # CMake build"
              echo "   make                                    # Makefile build"
              echo "   cppcheck --enable=all src/              # Static analysis"
            fi
          '';
        };
      }
    );
}
