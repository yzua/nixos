#!/usr/bin/env bash
# Sync skills from GitHub repos to ~/.local/share/skills/
set -euo pipefail

SKILLS_DIR="$HOME/.local/share/skills"
mkdir -p "$SKILLS_DIR"

# Format: "repo|skill-path|output-name"
SKILLS=(
	"vercel-labs/skills|find-skills|find-skills"
	"vercel-labs/agent-skills|react-best-practices|vercel-react-best-practices"
	"anthropics/skills|frontend-design|frontend-design"
	"remotion-dev/skills|remotion|remotion-best-practices"
	"vercel-labs/agent-browser|agent-browser|agent-browser"
	"inferen-sh/skills|tools/video/ai-video-generation|ai-video-generation"
	"nextlevelbuilder/ui-ux-pro-max-skill|.claude/skills/ui-ux-pro-max|ui-ux-pro-max"
	"obra/superpowers|brainstorming|brainstorming"
	"coreyhaines31/marketingskills|seo-audit|seo-audit"
	"vercel-labs/next-skills|next-best-practices|next-best-practices"
	"shadcn/ui|shadcn|shadcn"
	"obra/superpowers|systematic-debugging|systematic-debugging"
	"obra/superpowers|writing-plans|writing-plans"
	"squirrelscan/skills|audit-website|audit-website"
	"obra/superpowers|using-superpowers|using-superpowers"
	"anthropics/skills|webapp-testing|webapp-testing"
	"obra/superpowers|test-driven-development|test-driven-development"
	"roin-orca/skills|simple|simple"
	"vercel-labs/agent-skills|web-design-guidelines|web-design-guidelines"
	"SimoneAvogadro/android-reverse-engineering-skill|plugins/android-reverse-engineering/skills/android-reverse-engineering|android-reverse-engineering"
	"Eyali1001/apkre|apk-audit|apk-audit"
	"narlyseorg/superhackers|security-assessment|security-assessment"
	"narlyseorg/superhackers|assessment-orchestrator|assessment-orchestrator"
	"supercent-io/skills-template|security-best-practices|security-best-practices"
	"supercent-io/skills-template|workflow-automation|workflow-automation"
	"microsoft/playwright-cli|playwright-cli|playwright-cli"
	"ChromeDevTools/chrome-devtools-mcp|skills/chrome-devtools-cli|chrome-devtools-cli"
	"callstackincubator/agent-device|agent-device|agent-device"
)

echo "Syncing ${#SKILLS[@]} skills to $SKILLS_DIR..."

success=0
failed=0
current_tmpdir=""

cleanup_tmpdir() {
	[[ -n "${current_tmpdir:-}" ]] && rm -rf "$current_tmpdir"
}
trap cleanup_tmpdir EXIT

for entry in "${SKILLS[@]}"; do
	IFS='|' read -r repo skill_path skill_name <<<"$entry"
	target="$SKILLS_DIR/$skill_name"

	echo -n "  → $skill_name: "

	tmpdir=$(mktemp -d)
	current_tmpdir="$tmpdir"

	# Clone the repo
	if ! git clone --quiet --depth 1 --filter=blob:none --sparse "https://github.com/$repo.git" "$tmpdir/repo" 2>/dev/null; then
		echo "❌ clone failed"
		failed=$((failed + 1))
		rm -rf "$tmpdir"
		continue
	fi

	# Try to find the skill directory
	skill_dir=""

	# 1. Try exact skill_path with skills/ prefix
	git -C "$tmpdir/repo" sparse-checkout set "skills/$skill_path" 2>/dev/null || true
	[[ -f "$tmpdir/repo/skills/$skill_path/SKILL.md" ]] && skill_dir="$tmpdir/repo/skills/$skill_path"

	# 2. Try skills/skill_path directly
	if [[ -z "$skill_dir" ]]; then
		git -C "$tmpdir/repo" sparse-checkout set "skills" 2>/dev/null || true
		[[ -f "$tmpdir/repo/skills/$skill_path/SKILL.md" ]] && skill_dir="$tmpdir/repo/skills/$skill_path"
	fi

	# 3. Try skill_path at root
	if [[ -z "$skill_dir" ]]; then
		git -C "$tmpdir/repo" sparse-checkout set "$skill_path" 2>/dev/null || true
		[[ -f "$tmpdir/repo/$skill_path/SKILL.md" ]] && skill_dir="$tmpdir/repo/$skill_path"
	fi

	# 4. Try plugins pattern
	if [[ -z "$skill_dir" ]]; then
		git -C "$tmpdir/repo" sparse-checkout set "plugins" 2>/dev/null || true
		found=$(find "$tmpdir/repo/plugins" -maxdepth 5 -name "SKILL.md" 2>/dev/null | head -1)
		[[ -n "$found" ]] && skill_dir=$(dirname "$found")
	fi

	if [[ -n "$skill_dir" && -f "$skill_dir/SKILL.md" ]]; then
		rm -rf "$target"
		cp -r "$skill_dir" "$target"
		echo "✔"
		success=$((success + 1))
	else
		echo "⚠ SKILL.md not found"
		failed=$((failed + 1))
	fi

	rm -rf "$tmpdir"
	current_tmpdir=""
done

echo ""
echo "✓ Synced $success skills ($failed failed) to $SKILLS_DIR"
echo ""
echo "Run 'just home' to symlink to opencode profiles."
