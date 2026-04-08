# Python

This is a Python development template with venv and a comprehensive toolchain.

---

## Initialization

```bash
nix flake init -t "/home/yz/System/dev-shells#python-venv"
```

## Usage

- `nix develop`: opens up a `bash` shell with the venv environment
- Create `requirements.txt` to auto-install dependencies on shell entry

## Included tools

- **Core**: python3, venv, pip (if requirements.txt exists)
- **Quality**: ruff, black, isort, flake8, mypy, bandit, safety, vulture
- **LSP**: pylsp-mypy, pyls-isort, pyls-flake8
- **Debug/Test**: ptpython, pudb, pytest, pytest-cov, pytest-xdist, coverage
- **Data**: numpy, pandas, matplotlib, scipy, scikit-learn
- **Jupyter**: jupyterlab, notebook
- **Web**: django, flask, fastapi, uvicorn
- **HTTP**: requests, urllib3, aiohttp
- **Database**: sqlalchemy, psycopg2, pymongo, redis
- **Docs**: sphinx, mkdocs
- **Cloud**: boto3, docker, kubernetes
- **Automation**: fabric, ansible, paramiko

## Reference

1. [wiki/Flakes](https://nixos.wiki/wiki/Flakes)
2. [Venv](https://docs.python.org/3/library/venv.html) - used for python package management
3. [wiki/python](https://github.com/NixOS/nixpkgs/blob/master/doc/languages-frameworks/python.section.md)
