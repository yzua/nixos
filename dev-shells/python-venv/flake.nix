# Nix flake for a Python virtual environment development template.
{
  description = "Python venv development template";

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
        pythonPackages = pkgs.python3Packages;
      in
      {
        devShells.default = pkgs.mkShell {
          name = "python-venv";
          venvDir = "./.venv";
          buildInputs = [
            # A Python interpreter including the 'venv' module is required to bootstrap
            # the environment.
            pythonPackages.python

            # This executes some shell code to initialize a venv in $venvDir before
            # dropping into the shell
            pythonPackages.venvShellHook

            # Code quality tools
            pkgs.ruff
            pythonPackages.black
            pythonPackages.isort
            pythonPackages.flake8
            pythonPackages.mypy
            pythonPackages.bandit
            pythonPackages.safety
            pythonPackages.vulture

            # LSP and IDE support
            pythonPackages.pylsp-mypy
            pythonPackages.pyls-isort
            pythonPackages.pyls-flake8

            # Debugging and testing
            pythonPackages.ptpython
            pythonPackages.pudb
            pythonPackages.pytest
            pythonPackages.pytest-cov
            pythonPackages.pytest-xdist
            pythonPackages.coverage

            # Data science
            pythonPackages.numpy
            pythonPackages.pandas
            pythonPackages.matplotlib
            pythonPackages.scipy
            pythonPackages.scikit-learn

            # Jupyter
            pythonPackages.jupyterlab
            pythonPackages.notebook

            # Web frameworks
            pythonPackages.django
            pythonPackages.flask
            pythonPackages.fastapi
            pythonPackages.uvicorn

            # HTTP and async
            pythonPackages.requests
            pythonPackages.urllib3
            pythonPackages.aiohttp

            # Database connectors
            pythonPackages.sqlalchemy
            pythonPackages.psycopg2
            pythonPackages.pymongo
            pythonPackages.redis

            # Documentation
            pythonPackages.sphinx
            pythonPackages.mkdocs

            # Cloud and deployment
            pythonPackages.boto3
            pythonPackages.docker
            pythonPackages.kubernetes

            # Automation
            pythonPackages.fabric
            pythonPackages.ansible
            pythonPackages.paramiko
          ]
          ++ pkgs.lib.optionals (builtins.pathExists ./requirements.txt) [ pythonPackages.pip ];

          # Run this command, only after creating the virtual environment
          postVenvCreation = pkgs.lib.optionalString (builtins.pathExists ./requirements.txt) ''
            unset SOURCE_DATE_EPOCH
            pip install -r requirements.txt
          '';

          # Now we can execute any commands within the virtual environment.
          # This is optional and can be left out to run pip manually.
          postShellHook = ''
            # allow pip to install wheels
            unset SOURCE_DATE_EPOCH

            # Show helpful message if requirements.txt is missing
            if [ ! -f requirements.txt ]; then
              echo "⚠️  Warning: requirements.txt not found. Create it to install dependencies automatically."
            fi
          '';
        };
      }
    );
}
