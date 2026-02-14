#!/usr/bin/env bash
set -euo pipefail

# Extract inline pkgs.writeShellScript/writeShellScriptBin bodies from .nix files
# and lint them with shellcheck.
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

awk_script="$tmp_dir/extract.awk"
cat > "$awk_script" <<'AWK'
function count_char(str, ch,    i, n) {
  n = 0
  for (i = 1; i <= length(str); i++) {
    if (substr(str, i, 1) == ch) {
      n += 1
    }
  }
  return n
}

function sanitize_path(path, value) {
  value = path
  gsub(/[\/[:space:]]+/, "__", value)
  return value
}

function normalize_line(line, value) {
  value = line
  gsub(/''\$\{/, "__BASH_ESC_OPEN__", value)
  gsub(/\$\{[^}]*\}/, "__NIX_INTERP__", value)
  gsub(/__BASH_ESC_OPEN__/, "${", value)
  return value
}

function flush_block(    out, i, line, safe, block_name, indent, min_indent, current_indent) {
  if (line_count == 0) {
    in_block = 0
    return
  }

  min_indent = -1
  for (i = 1; i <= line_count; i++) {
    line = lines[i]
    if (line ~ /[^[:space:]]/) {
      match(line, /^[[:space:]]*/)
      current_indent = RLENGTH
      if (min_indent < 0 || current_indent < min_indent) {
        min_indent = current_indent
      }
    }
  }
  if (min_indent < 0) {
    min_indent = 0
  }

  # Skip template-heavy blocks that embed Nix-level conditionals inside the shell
  # body; these are not reliably lintable as standalone Bash.
  for (i = 1; i <= line_count; i++) {
    if (lines[i] ~ /\$\{lib\./) {
      in_block = 0
      line_count = 0
      script_name = ""
      start_line = 0
      return
    }
  }

  block_index += 1
  safe = sanitize_path(src)
  block_name = script_name
  gsub(/[^[:alnum:]_.-]+/, "_", block_name)
  out = sprintf("%s/%s__L%d__%d__%s.sh", tmpdir, safe, start_line, block_index, block_name)

  for (i = 1; i <= line_count; i++) {
    line = lines[i]
    if (length(line) > min_indent) {
      line = substr(line, min_indent + 1)
    } else {
      line = ""
    }
    print normalize_line(line) > out
  }

  close(out)
  print out

  in_block = 0
  line_count = 0
  script_name = ""
  start_line = 0
}

{
  # Track writeShellApplication scope with a simple brace counter.
  if (!in_wsa && $0 ~ /writeShellApplication[[:space:]]*\{/) {
    in_wsa = 1
    wsa_depth = 0
  }
  if (in_wsa) {
    wsa_depth += count_char($0, "{")
    wsa_depth -= count_char($0, "}")
    if (wsa_depth <= 0) {
      in_wsa = 0
      wsa_depth = 0
      pending_wsa_text = 0
    }
  }

  if (!in_block) {
    # Capture writeShellScript/writeShellScriptBin with opening '' on same or later line.
    if (match($0, /writeShellScript(Bin)?[[:space:]]+"[^"]+"/)) {
      pending_script_name = substr($0, RSTART, RLENGTH)
      sub(/.*"/, "", pending_script_name)
      sub(/".*/, "", pending_script_name)
      pending_script = 1
      if (index($0, "''") > 0) {
        script_name = pending_script_name
        in_block = 1
        start_line = NR + 1
        line_count = 0
        pending_script = 0
      }
      next
    }

    if (pending_script) {
      if (index($0, "''") > 0) {
        script_name = pending_script_name
        in_block = 1
        start_line = NR + 1
        line_count = 0
      } else if ($0 ~ /[);][[:space:]]*$/) {
        pending_script = 0
      }
      next
    }

    # Capture writeShellApplication text = '' blocks.
    if (in_wsa && $0 ~ /text[[:space:]]*=[[:space:]]*''/) {
      script_name = "writeShellApplication"
      in_block = 1
      start_line = NR + 1
      line_count = 0
      pending_wsa_text = 0
      next
    }

    if (in_wsa && $0 ~ /text[[:space:]]*=/) {
      pending_wsa_text = 1
      next
    }

    if (in_wsa && pending_wsa_text) {
      if (index($0, "''") > 0) {
        script_name = "writeShellApplication"
        in_block = 1
        start_line = NR + 1
        line_count = 0
      } else if ($0 ~ /;[[:space:]]*$/) {
        pending_wsa_text = 0
      }
    }
    next
  }

  if ($0 ~ /^[[:space:]]*''[[:space:]]*[^[:alnum:]_]*$/) {
    flush_block()
    next
  }

  line_count += 1
  lines[line_count] = $0
}

END {
  if (in_block) {
    flush_block()
  }
}
AWK

mapfile -t extracted_scripts < <(
  rg --files -g '*.nix' . | while IFS= read -r file; do
    awk -v tmpdir="$tmp_dir" -v src="$file" -f "$awk_script" "$file"
  done
)

if (( ${#extracted_scripts[@]} == 0 )); then
  echo "No inline writeShellScript blocks found."
  exit 0
fi

printf '%s\0' "${extracted_scripts[@]}" | xargs -0 -r nix run nixpkgs#shellcheck -- \
  -s bash \
  -S error \
  -e SC1114,SC1128,SC2239
echo "✔ Inline Nix shell scripts passed! (${#extracted_scripts[@]} blocks)"
