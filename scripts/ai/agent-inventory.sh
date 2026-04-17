#!/usr/bin/env bash
# agent-inventory.sh - Interactive AI tool inventory browser.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/logging.sh
source "${SCRIPT_DIR}/../lib/logging.sh"
# shellcheck source=scripts/lib/require.sh
source "${SCRIPT_DIR}/../lib/require.sh"
# shellcheck source=scripts/lib/fzf-theme.sh
source "${SCRIPT_DIR}/../lib/fzf-theme.sh"
# shellcheck source=scripts/ai/_inventory-helpers.sh
source "${SCRIPT_DIR}/_inventory-helpers.sh"
# shellcheck source=scripts/ai/_inventory-collectors.sh
source "${SCRIPT_DIR}/_inventory-collectors.sh"

need_cmd fzf

usage() {
	cat <<'EOF'
Usage: ai-agent-inventory [--tool TOOL] [--section SECTION]

Dynamic AI tool inventory browser.

TOOL values:
  opencode | claude | codex | gemini | all

SECTION values:
  all | profile | model | small_model | command | plugin | mcp | provider |
  agent | category | skill | hook | model_alias | reasoning_effort

Without --tool/--section, fzf pickers are shown.
EOF
}

pick_tool() {
	printf '%s\n' "all" "opencode" "claude" "codex" "gemini" |
		fzf --height=40% --reverse --header="Select Tool Family"
}

pick_section() {
	local rows_file="$1"
	{
		printf 'all\tALL sections\n'
		awk -F'\t' '{count[$2]++} END {for (k in count) printf "%s\t%d entries\n", k, count[k]}' "$rows_file" | sort
	} |
		fzf --height=45% --reverse --header="Select Section" --with-nth=1,2 --delimiter=$'\t' |
		cut -f1
}

tool=""
section=""
section_locked="false"
while [[ $# -gt 0 ]]; do
	case "$1" in
	--tool)
		shift
		if [[ $# -eq 0 ]]; then
			error_exit "--tool requires a value"
		fi
		tool="$1"
		;;
	--section)
		shift
		if [[ $# -eq 0 ]]; then
			error_exit "--section requires a value"
		fi
		section="$1"
		section_locked="true"
		;;
	-h | --help)
		usage
		exit 0
		;;
		*)
		usage >&2
		error_exit "Unknown argument: $1"
		;;
	esac
	shift
done

if [[ -z "$tool" ]]; then
	tool="$(pick_tool)"
	if [[ -z "${tool:-}" ]]; then
		exit 0
	fi
fi

tmp_rows="$(mktemp)"
tmp_filtered="$(mktemp)"
trap 'rm -f "$tmp_rows" "$tmp_filtered"' EXIT

collect_rows_for_tool "$tool" | dedupe_rows | sort -u >"$tmp_rows"

if [[ ! -s "$tmp_rows" ]]; then
	error_exit "No inventory data found for tool: $tool"
fi

while true; do
	if [[ -z "$section" ]]; then
		section="$(pick_section "$tmp_rows")"
		if [[ -z "${section:-}" ]]; then
			exit 0
		fi
	fi

	if [[ "$section" == "all" ]]; then
		cp "$tmp_rows" "$tmp_filtered"
	else
		awk -F'\t' -v want="$section" '$2 == want' "$tmp_rows" >"$tmp_filtered"
	fi

	if [[ ! -s "$tmp_filtered" ]]; then
		print_error "No entries found for tool=$tool section=$section"
		if [[ "$section_locked" == "true" ]]; then
			exit 1
		fi
		section=""
		continue
	fi

	if [[ "$section_locked" == "true" ]]; then
		sanitize <"$tmp_filtered"
		exit 0
	fi

	selected="$({
		fzf --height=90% \
			--reverse \
			--header="${tool}/${section}: filter entries (ENTER opens source file, ESC back)" \
			--delimiter=$'\t' \
			--with-nth=1,2,3,4 \
			--preview 'printf "Tool: %s\nKind: %s\nName: %s\nDetail: %s\nSource: %s\n" {1} {2} {3} {4} {5} | sanitize' \
			<"$tmp_filtered"
	} || true)"

	if [[ -z "${selected:-}" ]]; then
		if [[ "$section_locked" == "true" ]]; then
			exit 0
		fi
		section=""
		continue
	fi

	sel_source="$(printf '%s\n' "$selected" | awk -F'\t' '{print $5}')"

	if [[ -n "${sel_source:-}" ]] && [[ -e "$sel_source" ]]; then
		editor_cmd="${EDITOR:-${VISUAL:-nvim}}"
		if command -v "$editor_cmd" >/dev/null 2>&1; then
			"$editor_cmd" "$sel_source"
			echo "Opened: $sel_source"
		elif command -v nvim >/dev/null 2>&1; then
			nvim "$sel_source"
			echo "Opened: $sel_source"
		elif command -v less >/dev/null 2>&1; then
			less "$sel_source"
			echo "Viewed: $sel_source"
		else
			printf '%s\n' "$selected" | sanitize
		fi
	else
		printf '%s\n' "$selected" | sanitize
	fi

	if [[ "$section_locked" == "true" ]]; then
		exit 0
	fi

	section=""
done
