#!/usr/bin/env bash
# help.sh - AI-powered command assistant
# Usage: ./help.sh "how to list files" -> "ls -la" (automatically copied to clipboard)

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASK_SCRIPT="$SCRIPT_DIR/ask.sh"

# shellcheck source=/dev/null
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/logging.sh"

# Function to show usage
show_usage() {
	echo "Usage: $0 \"your question about commands\""
	echo ""
	echo "Examples:"
	echo "  $0 \"how to list files\""
	echo "  $0 \"find large files in directory\""
	echo "  $0 \"compress a folder\""
	echo "  $0 \"check disk space\""
	echo ""
	echo "This script provides one-line command answers without explanations."
	echo "Commands are automatically copied to clipboard."
}

# Check if ask.sh exists
if [[ ! -f "$ASK_SCRIPT" ]]; then
	print_error "ask.sh not found at $ASK_SCRIPT"
	exit 1
fi

# Check if question is provided
if [[ $# -eq 0 ]]; then
	print_error "No question provided"
	echo ""
	show_usage
	exit 1
fi

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
	show_usage
	exit 0
fi

QUESTION="$*"

# System prompt for command assistance
SYSTEM_PROMPT="You are a Linux command-line expert working on a NixOS system. Provide ONLY the exact command without any explanation. Use the most practical and modern Linux commands with appropriate flags. For file operations, prefer modern tools. For system info, use standard Linux commands. For package management on NixOS, use 'nix shell' or 'nix run' commands. Always provide complete, ready-to-use commands. If multiple commands are needed, separate them with &&. Respond with ONLY the command, no explanation or extra text."

# Call ask.sh with system prompt and copy to clipboard
exec "$ASK_SCRIPT" -c -s "$SYSTEM_PROMPT" "$QUESTION"
