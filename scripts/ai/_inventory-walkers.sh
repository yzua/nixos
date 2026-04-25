#!/usr/bin/env bash
# _inventory-walkers.sh - Generic directory-walking helpers for agent inventory.
# Source this file after sourcing _inventory-helpers.sh.
#
# These are reusable utilities that walk directories and emit TSV rows via
# the `row()` helper from _inventory-helpers.sh.  Per-tool collectors that
# combine these walkers with tool-specific logic live in _inventory-collectors.sh.

# List skills from a single base directory.
list_skill_dirs() {
	local base="$1"
	local scope="$2"
	if [[ ! -d "$base" ]]; then
		return 0
	fi

	shopt -s nullglob
	local d
	for d in "$base"/*; do
		[[ -d "$d" ]] || continue
		local skill_file="$d/SKILL.md"
		if [[ -f "$skill_file" ]]; then
			row "$scope" "skill" "$(basename "$d")" "$(basename "$base")" "$skill_file"
		else
			row "$scope" "skill" "$(basename "$d")" "$(basename "$base")" "$d"
		fi
	done
	shopt -u nullglob
}

# Walk skill subdirectories from multiple base dirs, deduplicating by name.
# Emits rows via `row()` for each unique skill.
#   $1        scope       row scope tag
#   $2        kind        "skill" or "command"
#   $3        detail_mode "accumulate" (comma-separate source names) or "first"
#   ${@:4}    base dirs to walk
_walk_skill_dirs() {
	local scope="$1" kind="$2" detail_mode="$3"
	shift 3

	declare -A seen_sources=()
	declare -A seen_path=()

	local base d skill
	for base in "$@"; do
		[[ -d "$base" ]] || continue
		shopt -s nullglob
		for d in "$base"/*; do
			[[ -d "$d" ]] || continue
			skill="$(basename "$d")"
			if [[ -n "${seen_sources[$skill]:-}" ]]; then
				[[ "$detail_mode" == "accumulate" ]] && seen_sources[$skill]="${seen_sources[$skill]}, $(basename "$base")"
			else
				seen_sources[$skill]="$(basename "$base")"
				if [[ -f "$d/SKILL.md" ]]; then
					seen_path[$skill]="$d/SKILL.md"
				else
					seen_path[$skill]="$d"
				fi
			fi
		done
		shopt -u nullglob
	done

	local name_col
	for skill in "${!seen_sources[@]}"; do
		if [[ "$kind" == "command" ]]; then
			name_col="/$skill"
		else
			name_col="$skill"
		fi
		row "$scope" "$kind" "$name_col" "${seen_sources[$skill]}" "${seen_path[$skill]}"
	done
}

# List skills from multiple base directories, deduplicating by skill name.
# Comma-separates source names when a skill appears in multiple directories.
list_skill_dirs_merged() {
	_walk_skill_dirs "$1" "skill" "accumulate" "${@:2}"
}

# List skill slash commands from multiple base directories, deduplicating.
# Keeps only the first source for each skill name.
list_skill_commands_merged() {
	_walk_skill_dirs "$1" "command" "first" "${@:2}"
}

# List command files from a directory.
list_command_files() {
	local base="$1"
	local scope="$2"
	if [[ ! -d "$base" ]]; then
		return 0
	fi

	shopt -s nullglob
	local f
	for f in "$base"/*; do
		[[ -f "$f" ]] || continue
		row "$scope" "command" "$(basename "$f")" "file" "$f"
	done
	shopt -u nullglob
}

# List agent definition files from multiple directories, deduplicating by name.
list_agent_files_merged() {
	local scope="$1"
	shift

	declare -A seen=()
	local base f name
	for base in "$@"; do
		[[ -d "$base" ]] || continue
		shopt -s nullglob
		for f in "$base"/*.md; do
			[[ -f "$f" ]] || continue
			name="$(basename "$f" .md)"
			if [[ -z "${seen[$name]:-}" ]]; then
				row "$scope" "agent" "$name" "file agent definition" "$f"
				seen[$name]=1
			fi
		done
		shopt -u nullglob
	done
}
