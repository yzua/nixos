set shell := ["/usr/bin/env", "bash", "-c"]
set quiet

JUST := "just -u -f " + justfile()
header := "Available tasks:\n"

_default:
    @{{JUST}} --list-heading "{{header}}" --list

# Format all .nix files
format:
    @echo -e "\n➤ Formatting Nix files"
    @nix fmt
    @echo "✔ Formatting passed!"

# Lint all .nix files and bash scripts
lint:
    @echo -e "\n➤ Linting Nix files…"
    @\time -f "⏱ Completed in %E" nix run nixpkgs#statix -- check --ignore '.git/**'
    @echo "✔ Nix linting passed!"
    @{{JUST}} dead
    @echo -e "\n➤ Checking Bash scripts…"
    @\time -f "⏱ Completed in %E" find . -name "*.sh" -not -path "./.git/*" -exec nix run nixpkgs#shellcheck -- {} +
    @echo "✔ ShellCheck passed!"

# Scan for unused code in .nix files
dead:
    @echo -e "\n➤ Checking for dead Nix code…"
    @\time -f "⏱ Completed in %E" nix run nixpkgs#deadnix -- --fail --exclude ./home-manager/modules/terminal/zellij.nix .
    @echo "✔ Deadnix check passed!"

# Run nix flake check
check:
    @echo -e "\n➤ Running nix flake check…"
    @\time -f "⏱ Completed in %E" nix flake check --no-build
    @echo "✔ Flake check passed!"

# Check all missing imports
modules:
    @echo -e "\n➤ Checking modules"
    @\time -f "⏱ Completed in %E" bash ./scripts/build/modules-check.sh

# Switch Home-Manager generation
home:
    @echo -e "\n➤ Switching Home-Manager…"
    nh home switch '.?submodules=1'

# Switch NixOS generation
nixos:
    @echo -e "\n➤ Rebuilding NixOS…"
    nh os switch .

# All of the above, in order
all:
    @echo -e "\n➤ Running full pipeline…"
    {{JUST}} modules
    {{JUST}} lint
    {{JUST}} format
    {{JUST}} check
    {{JUST}} nixos
    {{JUST}} home
    @echo -e "✔ All done!"

# Generate system health report
report mode="full":
    sudo system-report {{mode}}

# View latest system report
report-view type="full":
    system-report {{ if type == "errors" { "view-errors" } else { "view" } }}

# Show what changed between current and previous NixOS generation
diff:
    @echo -e "\n➤ Diffing NixOS generations…"
    nvd diff $(ls -dv /nix/var/nix/profiles/system-*-link | tail -2)

# Update all flake inputs
update:
	nix flake update

# Clean up build artifacts and caches
clean:
	@echo -e "\n➤ Cleaning up build artifacts and caches…"
	@echo "[DEL] Cleaning Nix store (1 day older)..."
	nh clean all --keep 1
	@echo "[HM] Cleaning Home Manager generations..."
	home-manager expire-generations "-1 days"
	@echo "[OPT] Optimizing Nix store..."
	nix store optimise
	@echo -e "✔ Cleanup completed!"

# Install git pre-commit hook for config validation
install-hooks:
    @cp scripts/build/pre-commit-hook.sh .git/hooks/pre-commit
    @chmod +x .git/hooks/pre-commit
    @echo "✔ Pre-commit hook installed!"

# Audit systemd unit security exposure
security-audit:
    @echo -e "\n➤ Auditing systemd unit hardening…"
    @systemd-analyze security --no-pager 2>/dev/null | grep -E "EXPOSED|UNSAFE" || echo "✔ No EXPOSED/UNSAFE units found"
    @echo -e "\n➤ Running vulnix on system closure…"
    @if command -v vulnix >/dev/null 2>&1; then \
        vulnix --system 2>/dev/null || echo "⚠ vulnix found advisories (non-zero exit)"; \
      else \
        echo "⚠ vulnix not available (run 'just home' first)"; \
      fi

# Edit secrets with SOPS (uses RAM-backed tmpfs for security)
sops-edit:
	@echo -e "\n➤ Editing secrets with SOPS…"
	@./scripts/sops/sops-edit.sh || if [ $$? -eq 200 ]; then echo "No changes made."; else exit $$?; fi

# View decrypted secrets (read-only)
sops-view:
	@echo -e "\n➤ Viewing decrypted secrets…"
	@nix run nixpkgs#sops -- --decrypt secrets/secrets.yaml

# Add a single secret (reads value from stdin to avoid process list exposure)
secrets-add key:
	@echo "{{key}}" | grep -qE '^[a-zA-Z_][a-zA-Z0-9_]*$$' || (echo "✗ Invalid key name. Use alphanumeric characters and underscores only." && exit 1)
	@read -s -p "Enter secret value for '{{key}}': " VALUE && echo "" && \
	nix run nixpkgs#sops -- --set "[\"{{key}}\"] \"$$VALUE\"" secrets/secrets.yaml && \
	echo "✔ Secret added!"
