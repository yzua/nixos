# Python development environment (uv, ruff, poetry, pytest, etc).

{
  config,
  lib,
  pkgs,
  ...
}:

{
  programs = {
    zsh.shellAliases = {
      py = "python3";
      py2 = "python2";
      pyi = "python3 -i";
      pym = "python3 -m";
      pipi = "pip install";
      pipu = "pip install --upgrade";
      pipr = "pip uninstall";
      pipl = "pip list";
      pipf = "pip freeze";
      pipreq = "pip install -r requirements.txt";
      pipfreeze = "pip freeze > requirements.txt";
      uvi = "uv pip install";
      uvu = "uv pip install --upgrade";
      uvr = "uv pip uninstall";
      uvl = "uv pip list";
      uvf = "uv pip freeze";
      uvreq = "uv pip install -r requirements.txt";
      uvfreeze = "uv pip freeze > requirements.txt";
      uvinit = "uv init";
      uvadd = "uv add";
      uvdev = "uv add --dev";
      uvrun = "uv run";
      uvsync = "uv sync";
      venvc = "python3 -m venv venv";
      venva = "source venv/bin/activate";
      venvd = "deactivate";
      venvi = "venv/bin/pip install";
      rufff = "ruff format";
      ruffl = "ruff check";
      rufffi = "ruff format --check";
      blackf = "black --line-length 88";
      isortf = "isort --profile black";
      flake8l = "flake8 --max-line-length 88";
      mypyl = "mypy --ignore-missing-imports";
      pytestr = "pytest -v";
      pytestrw = "pytest -v --tb=short";
      coverage = "coverage run -m pytest && coverage report";
      jupyterl = "jupyter lab";
      jupytern = "jupyter notebook";
    };

    git.ignores = [
      "__pycache__/"
      "*.py[cod]"
      "*$py.class"
      "*.so"
      ".Python"
      "develop-eggs/"
      "downloads/"
      "eggs/"
      ".eggs/"
      "parts/"
      "sdist/"
      ".installed.cfg"
      "*.egg-info/"
      "*.egg"
      "MANIFEST"
      "*.manifest"
      "*.spec"
      "pip-log.txt"
      "pip-delete-this-directory.txt"
      "htmlcov/"
      ".tox/"
      ".coverage"
      ".coverage.*"
      "nosetests.xml"
      "coverage.xml"
      "*.cover"
      ".hypothesis/"
      "*.mo"
      "*.pot"
      "local_settings.py"
      "db.sqlite3"
      "db.sqlite3-journal"
      "instance/"
      ".webassets-cache"
      ".scrapy"
      "docs/_build/"
      "target/"
      ".ipynb_checkpoints"
      "profile_default/"
      "ipython_config.py"
      ".python-version"
      "Pipfile.lock"
      "__pypackages__/"
      "celerybeat-schedule"
      "celerybeat.pid"
      "*.sage.py"
      ".env"
      ".venv"
      "env/"
      "venv/"
      "ENV/"
      "env.bak/"
      "venv.bak/"
      ".spyderproject"
      ".spyproject"
      ".ropeproject"
      ".mypy_cache/"
      ".dmypy.json"
      "dmypy.json"
      ".pyre/"
    ];
  };

  home = {
    # Project-specific deps should use dev-shells or uv
    packages = with pkgs; [
      python3
      python3Packages.pip
      python3Packages.virtualenv
      poetry
      uv
      ruff
      python3Packages.mypy
      python3Packages.pytest
      python3Packages.setuptools
      python3Packages.wheel
      python3Packages.ipython
    ];

    sessionVariables = {
      PYTHONPATH = "${config.home.homeDirectory}/Projects/python";
      PYTHONSTARTUP = "${config.home.homeDirectory}/.pythonrc";
      PYTHONUTF8 = "1";
      PYTHONLEGACYWINDOWSSTDIO = "";
      VIRTUAL_ENV_DISABLE_PROMPT = "1";
      JUPYTER_CONFIG_DIR = "${config.home.homeDirectory}/.jupyter";
      JUPYTER_PLATFORM_DIRS = "1";
      POETRY_VIRTUALENVS_IN_PROJECT = "true";
      POETRY_NO_INTERACTION = "1";
      POETRY_PYPI_TOKEN_PYPI = "";
      PIP_DISABLE_PIP_VERSION_CHECK = "1";
      PIP_NO_WARN_SCRIPT_LOCATION = "1";
      PIP_INDEX_URL = "";
      UV_CACHE_DIR = "${config.xdg.cacheHome}/uv";
      UV_PYTHON_INSTALL_DIR = "${config.xdg.dataHome}/uv/python";
      UV_COMPILE_BYTECODE = "1";
      UV_LINK_MODE = "copy";
      PYTHONDEVMODE = "";
      PYTHONWARNINGS = "default";
    };

    sessionPath = [
      "${config.home.homeDirectory}/.local/bin"
      "${config.home.homeDirectory}/.poetry/bin"
    ];

    # Managed .pythonrc (replaces activation script for idempotent file management)
    file.".pythonrc".text = ''
      import atexit
      import os
      import readline
      import rlcompleter

      # Enable tab completion
      readline.parse_and_bind("tab: complete")

      # History file
      history_file = os.path.expanduser("~/.python_history")
      if os.path.exists(history_file):
        readline.read_history_file(history_file)
      atexit.register(readline.write_history_file, history_file)

      # Set history length
      readline.set_history_length(1000)

      # Enable colors in Python REPL
      os.environ['PYTHON_COLORS'] = '1'
    '';

    activation.createPythonWorkspace = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD mkdir -p $HOME/Projects/{python,django,flask,fastapi,data}
      $DRY_RUN_CMD mkdir -p $HOME/.jupyter
    '';
  };
}
