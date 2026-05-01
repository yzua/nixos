# Home Manager package aggregation (each chunk sets home.packages).

{
  imports = [
    ./applications.nix # Desktop apps, multimedia, productivity, GTK theming
    ./cli.nix # CLI tools: file mgmt, text processing, search
    ./custom # Custom package derivations (beads, chrome-devtools, cursor, kiro, prayer)
    ./development.nix # Dev tools, databases, reverse engineering
    ./lsp-servers.nix # Language servers for editors
    ./networking.nix # Network analysis, monitoring, security
    ./niri.nix # Niri compositor, Wayland utilities, GNOME helpers
    ./privacy.nix # Privacy and security tools
    ./system-monitoring.nix # System monitoring and diagnostics
    ./utilities.nix # Archive, system, audio utilities
  ];
}
