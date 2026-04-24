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

# List skills from multiple base directories, deduplicating by skill name.
list_skill_dirs_merged() {
	local scope="$1"
	shift

	declare -A skill_sources=()
	declare -A skill_source_path=()

	local base d skill
	for base in "$@"; do
		[[ -d "$base" ]] || continue
		shopt -s nullglob
		for d in "$base"/*; do
			[[ -d "$d" ]] || continue
			skill="$(basename "$d")"
			if [[ -n "${skill_sources[$skill]:-}" ]]; then
				skill_sources[$skill]="${skill_sources[$skill]}, $(basename "$base")"
			else
				skill_sources[$skill]="$(basename "$base")"
				if [[ -f "$d/SKILL.md" ]]; then
					skill_source_path[$skill]="$d/SKILL.md"
				else
					skill_source_path[$skill]="$d"
				fi
			fi
		done
		shopt -u nullglob
	done

	for skill in "${!skill_sources[@]}"; do
		row "$scope" "skill" "$skill" "${skill_sources[$skill]}" "${skill_source_path[$skill]}"
	done
}

# List skill slash commands from multiple base directories, deduplicating.
list_skill_commands_merged() {
	local scope="$1"
	shift

	declare -A cmd_source_path=()
	local base d skill
	for base in "$@"; do
		[[ -d "$base" ]] || continue
		shopt -s nullglob
		for d in "$base"/*; do
			[[ -d "$d" ]] || continue
			skill="$(basename "$d")"
			if [[ -z "${cmd_source_path[$skill]:-}" ]]; then
				if [[ -f "$d/SKILL.md" ]]; then
					cmd_source_path[$skill]="$d/SKILL.md"
				else
					cmd_source_path[$skill]="$d"
				fi
			fi
		done
		shopt -u nullglob
	done

	for skill in "${!cmd_source_path[@]}"; do
		row "$scope" "command" "/$skill" "skill slash command" "${cmd_source_path[$skill]}"
	done
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
