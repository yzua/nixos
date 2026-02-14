#!/usr/bin/env bash
# commit.sh - Generate conventional commit messages using AI
# Usage: ./commit.sh (in any git repository with staged changes)

# shellcheck disable=SC2209  # Disable false positive for environment variable assignments
set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASK_SCRIPT="$SCRIPT_DIR/ask.sh"

# shellcheck source=/dev/null
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/logging.sh"

# Function to show usage
show_usage() {
	echo "Usage: $0 [options]"
	echo ""
	echo "Generate conventional commit messages based on staged changes using glm-5."
	echo "This script analyzes git staged changes and creates proper commit messages."
	echo ""
	echo "Examples:"
	echo "  $0              # Generate commit messages for staged changes"
	echo "  $0 -h           # Show this help message"
	echo ""
	echo "The script will:"
	echo "  1. Check for staged changes"
	echo "  2. Analyze the diff content and repository context"
	echo "  3. Generate 3 conventional commit message options"
	echo "  4. Copy first option to clipboard for easy use"
}

# Check if ask.sh exists
if [[ ! -f "$ASK_SCRIPT" ]]; then
	print_error "ask.sh not found at $ASK_SCRIPT"
	exit 1
fi

# Parse command line arguments
while [[ $# -gt 0 ]]; do
	case "$1" in
	-h | --help)
		show_usage
		exit 0
		;;
	*)
		echo "Unknown option: $1"
		show_usage
		exit 1
		;;
	esac
done

# Check if we're in a git repository
if ! git rev-parse --git-dir >/dev/null 2>&1; then
	print_error "Not in a git repository"
	exit 1
fi

# Enhanced functions for better context
get_commit_context() {
	local num_commits=${1:-5}
	echo "Recent commit history (last $num_commits):"
	local git_output
	git_output="$(git --no-pager log --oneline -n "$num_commits" 2>/dev/null || echo "No previous commits")"
	echo "$git_output"
}

get_branch_context() {
	local current_branch
	current_branch=$(git branch --show-current 2>/dev/null || echo "unknown")
	echo "Current branch: $current_branch"

	# Try to detect base branch
	if git remote get-url origin >/dev/null 2>&1; then
		local default_branch
		default_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")
		if [[ "$current_branch" != "$default_branch" ]]; then
			local ahead_count
			ahead_count=$(git rev-list --count HEAD ^"origin/$default_branch" 2>/dev/null || echo "0")
			if [[ "$ahead_count" -gt 0 ]]; then
				echo "Commits ahead of $default_branch: $ahead_count"
			fi
		fi
	fi
}

analyze_project_type() {
	echo "Project Type Analysis:"

	# Detect project type from files and structure
	local project_type="Unknown"
	local languages=()
	local frameworks=()
	local build_systems=()

	# Analyze file extensions and patterns
	local files
	files="$(git ls-files 2>/dev/null | head -50 || echo "")"

	# Detect languages
	if echo "$files" | grep -E '\.(js|jsx|ts|tsx|json)$' >/dev/null; then
		languages+=("JavaScript/TypeScript")
		if echo "$files" | grep -E 'package\.json$' >/dev/null; then
			build_systems+=("npm/yarn")
		fi
		if echo "$files" | grep -E 'react|jsx|tsx' >/dev/null; then
			frameworks+=("React")
		fi
		if echo "$files" | grep -E 'vue|svelte|angular' >/dev/null; then
			frameworks+=("Frontend Framework")
		fi
	fi

	if echo "$files" | grep -E '\.(py)$' >/dev/null; then
		languages+=("Python")
		if echo "$files" | grep -E 'requirements\.txt|setup\.py|pyproject\.toml$' >/dev/null; then
			build_systems+=("pip/poetry")
		fi
		if echo "$files" | grep -E 'django|flask|fastapi' >/dev/null; then
			frameworks+=("Web Framework")
		fi
	fi

	if echo "$files" | grep -E '\.(rs)$' >/dev/null; then
		languages+=("Rust")
		if echo "$files" | grep -E 'Cargo\.toml$' >/dev/null; then
			build_systems+=("Cargo")
		fi
	fi

	if echo "$files" | grep -E '\.(go)$' >/dev/null; then
		languages+=("Go")
		if echo "$files" | grep -E 'go\.mod$' >/dev/null; then
			build_systems+=("Go modules")
		fi
	fi

	if echo "$files" | grep -E '\.(java|kt)$' >/dev/null; then
		languages+=("Java/Kotlin")
		if echo "$files" | grep -E 'pom\.xml|build\.gradle$' >/dev/null; then
			build_systems+=("Maven/Gradle")
		fi
	fi

	if echo "$files" | grep -E '\.(c|cpp|h|hpp)$' >/dev/null; then
		languages+=("C/C++")
		if echo "$files" | grep -E 'Makefile|CMakeLists\.txt$' >/dev/null; then
			build_systems+=("Make/CMake")
		fi
	fi

	if echo "$files" | grep -E '\.(nix|flake)$' >/dev/null; then
		languages+=("Nix/NixOS")
		build_systems+=("Nix Flakes")
	fi

	if echo "$files" | grep -E '\.dockerfile$|docker-compose\.yml$' >/dev/null; then
		frameworks+=("Docker")
	fi

	# Detect CI/CD
	if echo "$files" | grep -E '\.(yml|yaml)$' | grep -E 'github|gitlab|ci|cd' >/dev/null; then
		frameworks+=("CI/CD")
	fi

	# Detect project type
	if echo "$files" | grep -E 'README|CHANGELOG|LICENSE' >/dev/null; then
		project_type="Library/Package"
	elif echo "$files" | grep -E 'src|app|index\.' >/dev/null; then
		project_type="Application"
	elif echo "$files" | grep -E '\.(nix|yaml|toml)$' >/dev/null; then
		project_type="Configuration"
	elif echo "$files" | grep -E '\.(md|txt|rst)$' >/dev/null; then
		project_type="Documentation"
	fi

	echo "  Type: $project_type"
	[[ ${#languages[@]} -gt 0 ]] && echo "  Languages: ${languages[*]}"
	[[ ${#frameworks[@]} -gt 0 ]] && echo "  Frameworks: ${frameworks[*]}"
	[[ ${#build_systems[@]} -gt 0 ]] && echo "  Build Systems: ${build_systems[*]}"

	# File structure insights
	local total_files
	total_files="$(echo "$files" | wc -l | tr -d ' ')"
	echo "  Total files in repo: $total_files"

	# Directory structure
	local dirs
	dirs="$(echo "$files" | xargs dirname | sort -u | head -10 | tr '\n' ' ')"
	[[ -n "$dirs" ]] && echo "  Main directories: $dirs"
}

analyze_changes() {
	echo "Change analysis:"

	# Categorize changes
	local new_files
	new_files="$(git --no-pager diff --cached --name-status | grep '^A' | cut -f2- | tr '\n' ' ' || true)"
	local modified_files
	modified_files="$(git --no-pager diff --cached --name-status | grep '^M' | cut -f2- | tr '\n' ' ' || true)"
	local deleted_files
	deleted_files="$(git --no-pager diff --cached --name-status | grep '^D' | cut -f2- | tr '\n' ' ' || true)"

	[[ -n "$new_files" ]] && echo "New files: $new_files"
	[[ -n "$modified_files" ]] && echo "Modified files: $modified_files"
	[[ -n "$deleted_files" ]] && echo "Deleted files: $deleted_files"

	# Intelligent diff handling - use stat instead of full diff to avoid bat
	local diff_size
	diff_size="$(git --no-pager diff --cached | wc -l)"
	if [[ "$diff_size" -gt 1000 ]]; then
		print_warning "Large diff detected ($diff_size lines). Using summarized analysis."
		local diff_stat
		diff_stat="$(git --no-pager diff --cached --stat=120,120)"
		echo "$diff_stat"
		echo ""
		echo "Key file changes:"
		local diff_numstat
		diff_numstat="$(git --no-pager diff --cached --numstat | head -15 | awk '{printf "  %s: +%s -%s lines\n", $3, $1, $2}')"
		echo "$diff_numstat"
	else
		# Use stat instead of full diff to avoid bat opening
		local diff_summary
		diff_summary="$(git --no-pager diff --cached --stat)"
		echo "$diff_summary"
	fi
}

show_loading() {
	local pid=$1
	local delay=0.1
	local spinstr='|/\-'
	while ps -p "$pid" >/dev/null 2>&1; do
		local temp=${spinstr#?}
		printf "\r Generating commits... %c" "$spinstr"
		spinstr=$temp${spinstr%"$temp"}
		sleep "$delay"
	done
	printf "\r\033[K"
}

# Check if there are staged changes
if ! git diff --cached --quiet; then
	# Get comprehensive context silently
	get_branch_context >/dev/null
	get_commit_context >/dev/null
	analyze_changes >/dev/null

	# Enhanced intelligent system prompt with deep context awareness
	SYSTEM_PROMPT="You are an expert software engineer and conventional commit specialist. Analyze the repository structure, programming languages, frameworks, recent commit patterns, and current changes to generate exactly ONE optimal conventional commit message.

INTELLIGENT CONTEXT ANALYSIS:
1. Project Type Detection:
   - Identify if web app, CLI tool, library, config, docs, etc.
   - Detect programming languages and frameworks used
   - Recognize build systems (npm, cargo, make, etc.)
   - Identify testing frameworks and CI/CD setup

2. Change Impact Assessment:
   - Categorize by affected components (frontend, backend, api, config, etc.)
   - Determine user-facing vs internal changes
   - Assess breaking changes vs patches
   - Identify performance vs feature vs bug fix impacts

3. Semantic Analysis:
   - Understand the intent behind code changes
   - Distinguish between additions, modifications, deletions
   - Recognize dependency updates vs code changes
   - Identify configuration vs implementation changes

COMMIT TYPE SELECTION STRATEGY:
- feat: NEW functionality, features, capabilities for end users
- fix: BUG fixes, error resolution, broken functionality
- refactor: CODE restructuring without functional changes
- perf: PERFORMANCE improvements, optimizations
- docs: DOCUMENTATION only changes (README, comments, docs)
- style: CODE style, formatting, linting changes only
- test: TEST additions, modifications, improvements
- chore: MAINTENANCE, dependencies, build process, config
- ci: CI/CD, pipeline, automation changes
- build: BUILD system, compilation, packaging changes
- security: SECURITY fixes, vulnerabilities, hardening
- revert: UNDO of previous commits

SCOPE DETERMINATION:
- Use natural component boundaries (auth, api, ui, db, utils)
- Reflect logical grouping (user management, payments, analytics)
- Consider framework/module boundaries (react, server, client)
- Keep it concise but descriptive (2-15 characters max)

DESCRIPTION GUIDELINES:
- Imperative mood: \"add\" not \"added\", \"fix\" not \"fixed\"
- Present tense, active voice
- Focus on WHAT changed, not HOW
- User impact perspective when applicable
- Maximum 72 characters total (including scope)
- Minimum impact description, avoid redundancy

INTELLIGENT EXAMPLES BY PROJECT TYPE:

Web Application:
- feat(auth): implement user login with OAuth2
- fix(api): resolve user profile data leak
- refactor(components): extract reusable button component
- perf(images): lazy load product images
- docs(readme): update setup instructions

CLI Tool:
- feat(cli): add batch processing mode
- fix(parser): handle malformed input gracefully
- refactor(commands): simplify command structure
- test(unit): add argument validation tests
- chore(deps): update dependencies to latest

Library/Package:
- feat(api): add async streaming support
- fix(types): resolve TypeScript typing errors
- refactor(core): simplify internal architecture
- docs(api): update JSDoc for public methods
- build(release): prepare v2.0.0 release

Configuration/Infra:
- fix(docker): resolve container networking issue
- chore(k8s): update deployment manifests
- security(ssl): enforce HTTPS redirects
- ci(github): add automated testing workflow
- refactor(terraform): simplify resource structure

ADVANCED ANALYSIS RULES:
1. Prioritize user impact over implementation details
2. Consider the size and scope of changes
3. Maintain consistency with project's commit style
4. Use appropriate technical language for the project
5. Avoid vague terms like \"update\" or \"improve\"
6. Be specific about what functionality changed

CONTEXTUAL AWARENESS:
- Dependency updates: chore(deps): update react to v18
- Configuration changes: fix(config): resolve environment variables
- Refactoring large codebases: refactor(modules): restructure data access layer
- Breaking changes: feat(api): breaking: change user endpoint response format
- Performance optimizations: perf(database): optimize query performance
- Security patches: security(auth): prevent session hijacking

CRITICAL: Generate exactly 3 distinct commit message options, each with a different perspective on the changes. Each option should follow conventional commit format but focus on different aspects (user impact, technical implementation, or maintenance).

Provide exactly 3 numbered options:
1. [User-focused perspective] - emphasizes functionality and user impact
2. [Technical perspective] - emphasizes implementation details and code changes
3. [Maintenance perspective] - emphasizes dependencies, configuration, or housekeeping

Each option should be a complete, valid conventional commit message on its own line."

	# Enhanced repository analysis with project intelligence
	PROJECT_INSIGHTS=$(analyze_project_type)

	# Get comprehensive repository analysis
	REPO_ANALYSIS=$(
		cat <<EOF
Repository Analysis:

=== PROJECT TYPE & STRUCTURE ===
$PROJECT_INSIGHTS

=== GIT CONTEXT ===
$(get_branch_context)

$(get_commit_context 5)

=== CURRENT CHANGES ===
$(analyze_changes)
EOF
	)

	AI_PROMPT="Analyze this complete repository context and generate 3 conventional commit message options:

$REPO_ANALYSIS

Based on the repository context, recent commit patterns, branch information, and current changes, provide 3 distinct conventional commit message options from different perspectives."

	# Call ask.sh to generate commit message options
	OUTPUT_FILE=$(mktemp)
	"$ASK_SCRIPT" -s "$SYSTEM_PROMPT" "$AI_PROMPT" 2>/dev/null >"$OUTPUT_FILE" &
	bg_pid=$!
	show_loading $bg_pid
	wait $bg_pid
	COMMIT_OPTIONS=$(tr -d '\0' <"$OUTPUT_FILE")
	rm -f "$OUTPUT_FILE"

	# Extract numbered options from the AI response
	option1=$(echo "$COMMIT_OPTIONS" | grep -E '^1\.' | sed 's/^1\. *//' | head -1)
	option2=$(echo "$COMMIT_OPTIONS" | grep -E '^2\.' | sed 's/^2\. *//' | head -1)
	option3=$(echo "$COMMIT_OPTIONS" | grep -E '^3\.' | sed 's/^3\. *//' | head -1)

	# If no numbered options found, try to extract any commit messages
	if [[ -z "$option1" ]]; then
		all_commits=$(echo "$COMMIT_OPTIONS" | grep -E '^(feat|fix|refactor|docs|style|test|chore|perf|ci|build|security|release|revert)' | head -3)

		IFS=$'\n' read -r option1 option2 option3 <<<"$all_commits"
	fi

	# Display the 3 options
	echo ""
	print_info "Suggested commit messages:"
	echo ""

	if [[ -n "$option1" ]]; then
		echo "1. $option1"
	fi

	if [[ -n "$option2" ]]; then
		echo "2. $option2"
	fi

	if [[ -n "$option3" ]]; then
		echo "3. $option3"
	fi

	# Copy first option to clipboard for convenience
	if [[ -n "$option1" ]] && command -v wl-copy >/dev/null 2>&1; then
		echo "$option1" | wl-copy
		echo ""
		print_success "First option copied to clipboard!"
	fi

else
	print_error "No staged changes found"
	print_info "Stage your changes first:"
	echo "  git add <files>    # Stage specific files"
	echo "  git add .          # Stage all changes"
	echo "  git diff --cached  # Preview staged changes"
	exit 1
fi
