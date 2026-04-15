# Nix flake containing various project templates.

{
  description = "A collection of flake templates";

  outputs =
    _:

    {
      templates = {
        python-venv = {
          path = ./python-venv;
          description = "Python development template using venv";
        };

        rust-stable = {
          path = ./rust-stable;
          description = "Rust development template";
        };

        rust-nightly = {
          path = ./rust-nightly;
          description = "Rust development template using fenix";
        };

        deno = {
          path = ./deno;
          description = "Deno runtime development template";
        };

        bun = {
          path = ./bun;
          description = "Bun JavaScript/TypeScript development template";
        };

        nodejs = {
          path = ./nodejs;
          description = "Node.js JavaScript/TypeScript development template";
        };

        go = {
          path = ./go;
          description = "Go development template";
        };

        cpp = {
          path = ./cpp;
          description = "C/C++ development template";
        };

      };
    };
}
