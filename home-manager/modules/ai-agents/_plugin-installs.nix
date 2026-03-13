# Claude plugin installation — oh-my-claudecode and everything-claude-code.
{
  cfg,
  pkgs,
  lib,
}:
{
  installOhMyClaudeCode = lib.mkIf cfg.claude.enable (
    lib.hm.dag.entryAfter [ "setupClaudeConfig" ] ''
      if command -v claude &> /dev/null; then
        if ! claude plugin marketplace list 2>/dev/null | grep -q "omc"; then
          echo "📦 Adding oh-my-claudecode marketplace..."
          claude plugin marketplace add https://github.com/Yeachan-Heo/oh-my-claudecode 2>/dev/null || true
        fi

        if ! claude plugin list 2>/dev/null | grep -q "oh-my-claudecode"; then
          echo "📦 Installing oh-my-claudecode plugin..."
          claude plugin install oh-my-claudecode@omc 2>/dev/null || true
        fi
        echo "✓ oh-my-claudecode ready"
      fi
    ''
  );

  installEverythingClaudeCode = lib.mkIf cfg.claude.enable (
    lib.hm.dag.entryAfter [ "setupClaudeConfig" ] ''
      ECC_DIR="$HOME/.local/share/everything-claude-code"

      if command -v claude &> /dev/null; then
        if [[ -d "$ECC_DIR/.git" ]]; then
          echo "📦 Updating everything-claude-code..."
          ${pkgs.git}/bin/git -C "$ECC_DIR" pull --ff-only 2>/dev/null || true
        else
          echo "📦 Cloning everything-claude-code..."
          rm -rf "$ECC_DIR"
          ${pkgs.git}/bin/git clone --depth 1 https://github.com/affaan-m/everything-claude-code.git "$ECC_DIR" 2>/dev/null || true
        fi

        if ! claude plugin marketplace list 2>/dev/null | grep -q "everything-claude-code"; then
          echo "📦 Adding everything-claude-code marketplace..."
          claude plugin marketplace add affaan-m/everything-claude-code 2>/dev/null || true
        fi

        if ! claude plugin list 2>/dev/null | grep -q "everything-claude-code"; then
          echo "📦 Installing everything-claude-code plugin..."
          claude plugin install everything-claude-code@everything-claude-code 2>/dev/null || true
        fi

        if [[ -d "$ECC_DIR/rules" ]]; then
          mkdir -p "$HOME/.claude/rules"
          if [[ -d "$ECC_DIR/rules/common" ]]; then
            cp -r "$ECC_DIR/rules/common/"* "$HOME/.claude/rules/" 2>/dev/null || true
          fi
          if [[ -d "$ECC_DIR/rules/typescript" ]]; then
            cp -r "$ECC_DIR/rules/typescript/"* "$HOME/.claude/rules/" 2>/dev/null || true
          fi
          if [[ -d "$ECC_DIR/rules/python" ]]; then
            cp -r "$ECC_DIR/rules/python/"* "$HOME/.claude/rules/" 2>/dev/null || true
          fi
          if [[ -d "$ECC_DIR/rules/golang" ]]; then
            cp -r "$ECC_DIR/rules/golang/"* "$HOME/.claude/rules/" 2>/dev/null || true
          fi
          echo "✓ Installed ECC rules (common + typescript + python + golang)"
        fi

        echo "✓ everything-claude-code ready"
      fi
    ''
  );
}
