#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
# shellcheck disable=SC1091
source "${REPO_ROOT}/scripts/lib/test-helpers.sh"

# Extract base alias names from the bash agent registry (_def calls only, not the function definition).
bash_aliases="$(grep -oP '^_def\s+\K\S+' "${SCRIPT_DIR}/_agent-registry.sh" | sort -u)"

# Extract base alias names from the Nix alias spec.
# Only match alias = "literal" entries inside the aiAgentAliasSpecs list block.
nix_file="${REPO_ROOT}/home-manager/modules/ai-agents/helpers/_aliases.nix"
nix_base_aliases="$(awk '/aiAgentAliasSpecs = \[/,/^\s*\];/' "$nix_file" | grep -oP 'alias\s*=\s*"\K[^"$]+' | sort -u)"

# Compare: every base alias in Nix must exist in bash registry and vice versa.
nix_missing="$(comm -23 <(echo "$nix_base_aliases") <(echo "$bash_aliases"))"
bash_missing="$(comm -13 <(echo "$nix_base_aliases") <(echo "$bash_aliases"))"

if [[ -n "$nix_missing" ]]; then
	echo "FAIL: aliases in Nix but missing from bash registry (_agent-registry.sh):"
	while IFS= read -r line; do echo "  $line"; done <<< "$nix_missing"
	exit 1
fi

if [[ -n "$bash_missing" ]]; then
	echo "FAIL: aliases in bash registry but missing from Nix (_aliases.nix):"
	while IFS= read -r line; do echo "  $line"; done <<< "$bash_missing"
	exit 1
fi

# Count check: both registries should have the same number of base aliases.
bash_count="$(echo "$bash_aliases" | wc -l)"
nix_count="$(echo "$nix_base_aliases" | wc -l)"
assert_eq "$nix_count" "$bash_count" "base alias count matches between Nix ($nix_count) and bash ($bash_count)"

echo "All alias registry drift tests passed."
