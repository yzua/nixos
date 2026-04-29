# Home Manager package aggregation (each chunk sets home.packages).

{
  imports = [
    ./applications.nix # Desktop apps and GTK theming
    ./cli.nix # CLI tools: file mgmt, text processing, search
    ./custom # Custom package derivations (beads, chrome-devtools, cursor, kiro, prayer)
    ./development.nix # Dev tools, databases, reverse engineering
    ./lsp-servers.nix # Language servers for editors
    ./gnome.nix # Minimal GNOME utilities for Niri
    ./multimedia.nix # Media playback and processing
    ./networking.nix # Network analysis, monitoring, security
    ./niri.nix # Niri compositor and Wayland utilities
    ./privacy.nix # Privacy and security tools
    ./productivity.nix # Time tracking and focus
    ./system-monitoring.nix # System monitoring and diagnostics
    ./utilities.nix # Archive, system, audio utilities
  ];
}
