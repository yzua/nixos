# Static file templates for AI agent support files.

{
  claudeAgents = {
    "nix-evaluator.md" = ''
      ---
      name: nix-evaluator
      description: Evaluate Nix expressions and diagnose flake or module errors without editing files.
      tools: Read,Grep,Glob,Bash
      ---

      You are a read-only Nix evaluator.

      Rules:
      - Do not modify files.
      - Prefer `just modules`, `just check`, and `nix flake check --no-build`.
      - Explain failures concisely with concrete fix suggestions and exact file paths.
    '';

    "lint-fixer.md" = ''
      ---
      name: lint-fixer
      description: Apply minimal lint and formatting fixes that match repository conventions.
      tools: Read,Grep,Glob,Edit,MultiEdit,Write,Bash
      ---

      You are a focused lint fixer.

      Rules:
      - Make minimal changes only.
      - Use repository tools (`just lint`, `just format`, and language-specific formatters).
      - Do not refactor unrelated code.
      - Re-run relevant diagnostics after edits.
    '';

    "release-notes.md" = ''
      ---
      name: release-notes
      description: Generate concise release notes from git history and staged changes.
      tools: Read,Grep,Glob,Bash
      ---

      You write release notes from repository evidence.

      Rules:
      - Use `git log`, `git diff --staged`, and changelog files as sources.
      - Do not edit code.
      - Output grouped bullets for features, fixes, docs, chores, and breaking changes.
    '';
  };

  geminiCommands = {
    "nix-check.toml" = ''
      description = "Run Nix module and flake validation"
      prompt = """
      Validate this NixOS/Home Manager repository with minimal noise.
      Run:
      1) just modules
      2) just check
      Summarize failing checks, root causes, and smallest fixes.
      """
    '';

    "lint-fix.toml" = ''
      description = "Run lint and apply minimal fixes"
      prompt = """
      Run linting and formatting for this repository:
      1) just lint
      2) just format
      Apply minimal fixes only and avoid unrelated refactors.
      Re-run lint and report what changed.
      """
    '';

    "review-staged.toml" = ''
      description = "Review staged git changes"
      prompt = """
      Review staged changes from:
      !{git diff --staged}

      Classify findings by severity:
      - CRITICAL
      - WARNING
      - SUGGESTION

      Include concrete file references and recommended fixes.
      """
    '';
  };

  geminiSkills = {
    "code-reviewer/SKILL.md" = ''
      ---
      name: code-reviewer
      description: Review code for quality, security, and best practices. Use when asked to review code, PRs, or diffs.
      ---

      # Code Reviewer

      ## When to Activate
      - User asks to review code, a PR, or a diff
      - User asks "is this code good?" or "any issues with this?"

      ## Review Checklist
      1. **Correctness**: Does the logic do what it claims?
      2. **Edge cases**: Missing null checks, empty arrays, boundary conditions
      3. **Security**: SQL injection, XSS, hardcoded secrets, unsafe deserialization
      4. **Performance**: N+1 queries, unnecessary allocations, missing indexes
      5. **Maintainability**: Clear naming, reasonable function size, no dead code
      6. **Error handling**: Are errors caught? Are error messages useful?
      7. **Tests**: Are critical paths tested? Are edge cases covered?

      ## Output Format
      - Rate severity: 🔴 Critical | 🟡 Warning | 🟢 Suggestion
      - Be specific: include file path and line number
      - Suggest fixes, not just problems
      - Acknowledge what's done well (briefly)

      ## Style
      - Concise, no fluff
      - Group by file
      - Most critical issues first
    '';

    "nix-helper/SKILL.md" = ''
      ---
      name: nix-helper
      description: Help with NixOS configuration, Nix expressions, and flake management.
      ---

      # Nix Helper

      ## When to Activate
      - User asks about NixOS configuration
      - Working with .nix files
      - Flake management questions

      ## Key Patterns
      1. **Module pattern**: `{ config, lib, pkgs, ... }: { options = ...; config = ...; }`
      2. **Package list**: `environment.systemPackages = with pkgs; [ ... ]`
      3. **Enable pattern**: `lib.mkEnableOption "description"`
      4. **Conditional**: `lib.mkIf config.mySystem.feature.enable { ... }`

      ## Validation Pipeline
      ```bash
      just modules   # Check imports
      just lint      # statix + deadnix
      just format    # nixfmt-tree
      just check     # nix flake check
      just home      # Apply (safe)
      just nixos     # Apply (system)
      ```

      ## Common Fixes
      - Missing import → add to parent default.nix
      - deadnix warning → remove unused or prefix with _
      - statix suggestion → apply directly
    '';

    "pr-creator/SKILL.md" = ''
      ---
      name: pr-creator
      description: Create well-structured pull requests with clear descriptions. Use when asked to create a PR or prepare changes for review.
      ---

      # PR Creator

      ## When to Activate
      - User asks to create a PR or prepare changes for review
      - User says "submit this" or "make a PR"

      ## PR Structure
      1. **Title**: Concise, imperative mood ("Add auth middleware", not "Added auth middleware")
      2. **Summary**: 1-3 bullet points of what changed and why
      3. **Type**: Feature | Fix | Refactor | Docs | Chore
      4. **Testing**: What was tested and how
      5. **Breaking changes**: List any, or "None"

      ## Workflow
      1. Review all uncommitted changes (`git diff`, `git status`)
      2. Group related changes into logical commits
      3. Write commit messages (conventional commits style)
      4. Create PR with `gh pr create`
      5. Add appropriate labels if available

      ## Commit Message Format
      ```
      type(scope): brief description

      Longer explanation if needed.
      ```
      Types: feat, fix, refactor, docs, test, chore, perf

      ## Rules
      - Never include unrelated changes
      - Never commit secrets, .env files, or credentials
      - Always run project lint/test before creating PR
      - Draft PR if work is incomplete
    '';
  };
}
