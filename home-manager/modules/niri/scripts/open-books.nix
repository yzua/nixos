{ pkgsStable, ... }:
pkgsStable.writeScriptBin "open_books" ''
  #!/usr/bin/env bash
  set -euo pipefail

  BOOKS_DIR="$HOME/Downloads/books"

  # Find all book files and present them in a menu via wofi fallback
  BOOK=$(find "$BOOKS_DIR" -type f \( -iname "*.pdf" -o -iname "*.epub" -o -iname "*.djvu" \) | wofi --dmenu -p "Select a book" --width 1200 --lines 15)

  if [[ -n "$BOOK" ]]; then
      zathura "$BOOK" &
  else
      echo "No book selected."
  fi
''
