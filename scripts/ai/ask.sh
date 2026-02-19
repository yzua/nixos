#!/usr/bin/env bash
# ask.sh - AI API client using z.ai OpenAI-compatible API
# Usage: ./ask.sh [-d] [-s "system prompt"] "Your prompt here"
#   -d  Use deep model (glm-5) instead of default (GLM-4.5-air)
#   -s  Add system prompt for context

set -euo pipefail

# Configuration
API_URL="https://api.z.ai/api/coding/paas/v4"
DEFAULT_MODEL="glm-4.5-air"
DEEP_MODEL="glm-5"
API_KEY_FILE="/run/secrets/zai_api_key"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/logging.sh
source "${SCRIPT_DIR}/../lib/logging.sh"

# Function to show usage
show_usage() {
    echo "Usage: $0 [-d] [-c] [-s \"system prompt\"] \"Your prompt here\""
    echo ""
    echo "Options:"
    echo "  -d    Use deep model (glm-5) for better quality"
    echo "  -c    Copy response to clipboard using wl-clipboard"
    echo "  -s    Add system prompt for context"
    echo "  -h    Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 \"Write a Python function to calculate factorial\""
    echo "  $0 -d \"Explain quantum computing in simple terms\""
    echo "  $0 -c \"Summarize this text\""
    echo "  $0 -s \"You are a helpful assistant\" \"What is bash?\""
    echo ""
    echo "Default model: $DEFAULT_MODEL"
    echo "Deep model:    $DEEP_MODEL"
}

# Initialize variables
USE_DEEP_MODEL=false
COPY_TO_CLIPBOARD=false
SYSTEM_PROMPT=""
PROMPT=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--deep)
            USE_DEEP_MODEL=true
            shift
            ;;
        -c|--copy)
            COPY_TO_CLIPBOARD=true
            shift
            ;;
        -s|--system)
            if [[ $# -lt 2 ]]; then
                print_error "Option -s requires an argument"
                echo ""
                show_usage
                exit 1
            fi
            SYSTEM_PROMPT="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        -*)
            print_error "Unknown option: $1"
            echo ""
            show_usage
            exit 1
            ;;
        *)
            PROMPT="$PROMPT $1"
            shift
            ;;
    esac
done

# Remove leading space from prompt
PROMPT="${PROMPT# }"

# Set model based on flag
if [[ "$USE_DEEP_MODEL" == "true" ]]; then
    MODEL="$DEEP_MODEL"
else
    MODEL="$DEFAULT_MODEL"
fi

# Check if prompt is provided
if [[ -z "$PROMPT" ]]; then
    print_error "No prompt provided"
    echo ""
    show_usage
    exit 1
fi

# Check if API key file exists
if [[ ! -f "$API_KEY_FILE" ]]; then
    print_error "API key file not found at $API_KEY_FILE"
    print_info "Make sure the SOPS secret is properly configured and system is rebuilt"
    print_info "Try running: just nixos"
    exit 1
fi

# Read API key
API_KEY=$(cat "$API_KEY_FILE")

if [[ -z "$API_KEY" ]]; then
    print_error "API key is empty or unreadable"
    exit 1
fi

show_loading() {
    local pid=$1
    local delay=0.1
    local spinstr='|/\-'
    while ps -p "$pid" >/dev/null 2>&1; do
        local temp=${spinstr#?}
        printf "\r Thinking... %c" "$spinstr"
        spinstr=$temp${spinstr%"$temp"}
        sleep "$delay"
    done
    printf "\r\033[K"
}

# Create JSON payload with optional system prompt
if [[ -n "$SYSTEM_PROMPT" ]]; then
    PAYLOAD=$(jq -n \
        --arg model "$MODEL" \
        --arg system "$SYSTEM_PROMPT" \
        --arg prompt "$PROMPT" \
        '{
            "model": $model,
            "messages": [
                {
                    "role": "system",
                    "content": $system
                },
                {
                    "role": "user",
                    "content": $prompt
                }
            ],
            "temperature": 0.7,
            "max_tokens": 2000
        }')
else
    PAYLOAD=$(jq -n \
        --arg model "$MODEL" \
        --arg prompt "$PROMPT" \
        '{
            "model": $model,
            "messages": [
                {
                    "role": "user",
                    "content": $prompt
                }
            ],
            "temperature": 0.7,
            "max_tokens": 2000
        }')
fi

# Create temporary file for response
TEMP_RESPONSE=$(mktemp)
trap 'rm -f "$TEMP_RESPONSE"' EXIT

# Start API request in background and capture response to temp file
curl -s \
    -X POST \
    "$API_URL/chat/completions" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $API_KEY" \
    -d "$PAYLOAD" > "$TEMP_RESPONSE" 2>/dev/null &

# Get the PID of the curl process
CURL_PID=$!

# Show loading animation while request is in progress
show_loading $CURL_PID

# Wait for the curl process to complete
wait $CURL_PID

# Read response from temp file
RESPONSE=$(cat "$TEMP_RESPONSE")

# Clean up temp file
rm -f "$TEMP_RESPONSE"

# Parse response
CLEAN_RESPONSE=""
if command -v jq >/dev/null 2>&1; then
    # Parse with jq if available
    CLEAN_RESPONSE=$(echo "$RESPONSE" | jq -r '.choices[0].message.content' 2>/dev/null) || {
        print_error "Failed to parse API response"
        echo "Raw response:"
        echo "$RESPONSE" | head -5
        exit 1
    }
    echo "$CLEAN_RESPONSE"
else
    # Fallback without jq
    print_warning "jq not found, showing raw response"
    CLEAN_RESPONSE="$RESPONSE"
    echo "$CLEAN_RESPONSE"
fi

# Copy to clipboard if requested
if [[ "$COPY_TO_CLIPBOARD" == "true" ]]; then
    if command -v wl-copy >/dev/null 2>&1; then
        echo "$CLEAN_RESPONSE" | wl-copy
    else
        print_error "wl-copy not found. Install wl-clipboard package."
    fi
fi
