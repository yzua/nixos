# Nix flake for a PostgreSQL development environment.
{
  description = "PostgreSQL development template";

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
        pgDataDir = ".pg-data";
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            postgresql
            pgcli
            sqlc
          ];

          env = {
            PGDATA = pgDataDir;
            PGHOST = "localhost";
            PGPORT = "5432";
            PGDATABASE = "devdb";
          };

          shellHook = ''
            if [ ! -d "${pgDataDir}" ]; then
              echo "Initializing PostgreSQL data directory..."
              initdb -D "${pgDataDir}" --no-locale --encoding=UTF8
              echo "unix_socket_directories = '$PWD/${pgDataDir}'" >> "${pgDataDir}/postgresql.conf"
              echo "listen_addresses = '''" >> "${pgDataDir}/postgresql.conf"
              echo "port = 5432" >> "${pgDataDir}/postgresql.conf"
            fi

            echo "PostgreSQL development environment ready!"
            echo "   pg_ctl start     # Start PostgreSQL"
            echo "   pg_ctl stop      # Stop PostgreSQL"
            echo "   pgcli devdb      # Connect with pgcli"
            echo "   createdb myapp   # Create a database"
          '';
        };
      }
    );
}
