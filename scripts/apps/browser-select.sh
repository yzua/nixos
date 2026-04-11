#!/usr/bin/env bash
set -euo pipefail

url="${1:-}"

if [[ -n "$url" ]]; then
	if ! noctalia-shell ipc call plugin:browser-launcher openUrl "$url" >/dev/null 2>&1; then
		nohup noctalia-shell >/dev/null 2>&1 &
		sleep 0.35
		noctalia-shell ipc call plugin:browser-launcher openUrl "$url" >/dev/null 2>&1
	fi
	exit 0
fi

if ! noctalia-shell ipc call plugin:browser-launcher toggle >/dev/null 2>&1; then
	nohup noctalia-shell >/dev/null 2>&1 &
	sleep 0.35
	noctalia-shell ipc call plugin:browser-launcher toggle >/dev/null 2>&1
fi
