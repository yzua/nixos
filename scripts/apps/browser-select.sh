#!/usr/bin/env bash
set -euo pipefail

url="${1:-}"
noctalia_bin="${HOME}/.nix-profile/bin/noctalia-shell"

if [[ ! -x "$noctalia_bin" ]]; then
	noctalia_bin="noctalia-shell"
fi

if [[ -n "$url" ]]; then
	if ! "$noctalia_bin" ipc call plugin:browser-launcher openUrl "$url" >/dev/null 2>&1; then
		nohup "$noctalia_bin" >/dev/null 2>&1 &
		sleep 0.35
		"$noctalia_bin" ipc call plugin:browser-launcher openUrl "$url" >/dev/null 2>&1
	fi
	exit 0
fi

if ! "$noctalia_bin" ipc call plugin:browser-launcher toggle >/dev/null 2>&1; then
	nohup "$noctalia_bin" >/dev/null 2>&1 &
	sleep 0.35
	"$noctalia_bin" ipc call plugin:browser-launcher toggle >/dev/null 2>&1
fi
