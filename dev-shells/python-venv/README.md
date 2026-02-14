# Python

This is a minimal template for Python development with venv.

---

## Initialization

```bash
nix flake init -t "https://github.com/yzua/nixos-config/main?dir=dev-shells#python-venv"
```

## Usage

- `nix develop`: opens up a `bash` shell with the venv environment

## Reference

1. [wiki/Flakes](https://nixos.wiki/wiki/Flakes)
2. [Venv](https://docs.python.org/3/library/venv.html) - used for python package management
3. [wiki/python](https://github.com/NixOS/nixpkgs/blob/master/doc/languages-frameworks/python.section.md)
