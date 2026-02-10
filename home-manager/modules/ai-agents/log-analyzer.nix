# AI agent log analyzer and dashboard.

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.aiAgents;

  logAnalyzer = pkgs.writeShellScriptBin "ai-agent-analyze" ''
    #!/usr/bin/env bash
    set -euo pipefail

    LOG_DIR="${cfg.logging.directory}"

    usage() {
      echo "AI Agent Log Analyzer"
      echo ""
      echo "Usage: ai-agent-analyze <command> [options]"
      echo ""
      echo "Commands:"
      echo "  stats           Show statistics for all agents"
      echo "  errors [agent]  Show recent errors (optionally filter by agent)"
      echo "  sessions        Show session activity timeline"
      echo "  search <term>   Search logs for a term"
      echo "  tail [agent]    Live tail logs (optionally filter by agent)"
      echo "  report          Generate daily report"
      echo ""
      echo "Agents: claude, opencode, codex, gemini"
    }

    stats() {
      echo "═══════════════════════════════════════════════════════════════"
      echo "  AI Agent Statistics (Last 7 Days)"
      echo "═══════════════════════════════════════════════════════════════"
      echo ""
      
      for agent in claude opencode codex gemini; do
        sessions=$(find "$LOG_DIR" -name "$agent-*.log" -mtime -7 2>/dev/null | wc -l)
        errors=$(find "$LOG_DIR" -name "$agent-errors-*.log" -mtime -7 -exec cat {} \; 2>/dev/null | wc -l)
        
        if [ "$sessions" -gt 0 ] || [ "$errors" -gt 0 ]; then
          echo "  $agent:"
          echo "    Sessions: $sessions"
          echo "    Errors:   $errors"
          echo ""
        fi
      done
      
      echo "═══════════════════════════════════════════════════════════════"
      total_logs=$(du -sh "$LOG_DIR" 2>/dev/null | cut -f1 || echo "0")
      echo "  Total log size: $total_logs"
      echo "═══════════════════════════════════════════════════════════════"
    }

    errors() {
      agent="''${1:-*}"
      echo "Recent errors for: $agent"
      echo "────────────────────────────────────────────────────────────────"
      
      find "$LOG_DIR" -name "$agent-errors-*.log" -mtime -7 -exec sh -c '
        echo "File: $1"
        tail -20 "$1"
        echo ""
      ' _ {} \; 2>/dev/null | head -100
    }

    sessions() {
      echo "Session Activity Timeline (Last 24h)"
      echo "────────────────────────────────────────────────────────────────"
      
      find "$LOG_DIR" -name "*.log" ! -name "*-errors-*" -mtime -1 -exec sh -c '
        basename "$1" .log | sed "s/-[0-9]*-[0-9]*-[0-9]*$//"
      ' _ {} \; 2>/dev/null | sort | uniq -c | sort -rn | head -20
    }

    search_logs() {
      term="$1"
      echo "Searching for: $term"
      echo "────────────────────────────────────────────────────────────────"
      
      grep -rn --color=always "$term" "$LOG_DIR" 2>/dev/null | head -50
    }

    tail_logs() {
      agent="''${1:-*}"
      echo "Tailing logs for: $agent (Ctrl+C to stop)"
      echo "────────────────────────────────────────────────────────────────"
      
      tail -f "$LOG_DIR"/$agent-*.log 2>/dev/null
    }

    report() {
      echo "═══════════════════════════════════════════════════════════════"
      echo "  AI Agent Daily Report - $(date +%Y-%m-%d)"
      echo "═══════════════════════════════════════════════════════════════"
      echo ""
      
      echo "📊 Session Summary:"
      sessions
      echo ""
      
      echo "🔴 Error Summary:"
      for agent in claude opencode codex gemini; do
        count=$(find "$LOG_DIR" -name "$agent-errors-*.log" -mtime -1 -exec cat {} \; 2>/dev/null | wc -l)
        if [ "$count" -gt 0 ]; then
          echo "  $agent: $count errors"
        fi
      done
      echo ""
      
      echo "📝 Most Recent Errors:"
      find "$LOG_DIR" -name "*-errors-*.log" -mtime -1 -exec tail -5 {} \; 2>/dev/null | head -20
    }

    case "''${1:-help}" in
      stats)     stats ;;
      errors)    errors "''${2:-}" ;;
      sessions)  sessions ;;
      search)    search_logs "''${2:?Search term required}" ;;
      tail)      tail_logs "''${2:-}" ;;
      report)    report ;;
      *)         usage ;;
    esac
  '';

  errorPatternDetector = pkgs.writeShellScriptBin "ai-agent-patterns" ''
    #!/usr/bin/env bash

    LOG_DIR="${cfg.logging.directory}"
    PATTERNS_FILE="$LOG_DIR/.error-patterns.txt"

    echo "Analyzing error patterns..."
    echo "════════════════════════════════════════════════════════════════"

      cat "$LOG_DIR"/*-errors-*.log 2>/dev/null | \
      grep -oE "(Error|ERROR|error|Exception|EXCEPTION|failed|Failed|FAILED):? [^[:space:]]{0,100}" | \
      sort | uniq -c | sort -rn | head -20

    echo ""
    echo "════════════════════════════════════════════════════════════════"
    echo "Top exit codes:"
    grep -h "exited with code" "$LOG_DIR"/*.log 2>/dev/null | \
      grep -oE "code [0-9]+" | sort | uniq -c | sort -rn | head -10
  '';

  logDashboard = pkgs.writeShellScriptBin "ai-agent-dashboard" ''
    #!/usr/bin/env bash

    LOG_DIR="${cfg.logging.directory}"

    if ! command -v fzf >/dev/null 2>&1; then
      echo "Error: fzf is required for the dashboard"
      exit 1
    fi

    while true; do
      action=$(echo -e "📊 Stats\n🔴 Errors\n📋 Sessions\n🔍 Search\n📜 Tail Logs\n📄 Report\n🔮 Error Patterns\n❌ Exit" | \
        fzf --header="AI Agent Dashboard" --height=50% --reverse)
      
      case "$action" in
        "📊 Stats")         ai-agent-analyze stats; read -p "Press Enter..." ;;
        "🔴 Errors")        ai-agent-analyze errors; read -p "Press Enter..." ;;
        "📋 Sessions")      ai-agent-analyze sessions; read -p "Press Enter..." ;;
        "🔍 Search")        read -p "Search term: " term; ai-agent-analyze search "$term"; read -p "Press Enter..." ;;
        "📜 Tail Logs")     ai-agent-analyze tail ;;
        "📄 Report")        ai-agent-analyze report; read -p "Press Enter..." ;;
        "🔮 Error Patterns") ai-agent-patterns; read -p "Press Enter..." ;;
        "❌ Exit"|"")       exit 0 ;;
      esac
    done
  '';

in
{
  config = lib.mkIf (cfg.enable && cfg.logging.enable) {
    home.packages = [
      logAnalyzer
      errorPatternDetector
      logDashboard
    ];
  };
}
