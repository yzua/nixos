# Custom package derivations.

{
  imports = [
    ./beads.nix # Beads git-backed issue tracker (bd CLI)
    ./chrome-devtools.nix # Chrome DevTools MCP CLI wrapper
    ./cursor.nix # Cursor terminal agent CLI
    ./kiro.nix # Kiro CLI for agentic workflows
    ./prayer.nix # Custom prayer times indicator
  ];
}
