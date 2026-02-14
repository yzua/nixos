# Glance self-hosted dashboard with Gruvbox theme (localhost:8082).

{
  config,
  lib,
  constants,
  ...
}:

{
  options.mySystem.glance = {
    enable = lib.mkEnableOption "Glance dashboard";
  };

  config = lib.mkIf config.mySystem.glance.enable {
    services.glance = {
      enable = true;
      openFirewall = false; # SECURITY: Localhost only

      settings = {
        server = {
          host = "127.0.0.1";
          port = 8082;
        };

        branding = {
          logo-text = "Y";
          app-name = "Dashboard";
          hide-footer = true;
          app-background-color = constants.color.bg;
        };

        # Gruvbox Dark theme
        theme = {
          background-color = "0 0 16";
          primary-color = "43 59 81";
          positive-color = "61 66 44";
          negative-color = "6 96 59";
          contrast-multiplier = 1.1;
        };

        pages = [
          {
            name = "Home";

            # Markets widget at top (crypto + metals)
            head-widgets = [
              {
                type = "markets";
                hide-header = true;
                markets = [
                  {
                    symbol = "BTC-USD";
                    name = "Bitcoin";
                  }
                  {
                    symbol = "LTC-USD";
                    name = "Litecoin";
                  }
                  {
                    symbol = "XMR-USD";
                    name = "Monero";
                  }
                  {
                    symbol = "GC=F";
                    name = "Gold";
                  }
                  {
                    symbol = "SI=F";
                    name = "Silver";
                  }
                ];
              }
            ];

            columns = [
              # LEFT SIDEBAR
              {
                size = "small";
                widgets = [
                  # Search with bangs
                  {
                    type = "search";
                    search-engine = "duckduckgo";
                    new-tab = true;
                    bangs = [
                      {
                        title = "GitHub";
                        shortcut = "!gh";
                        url = "https://github.com/search?q={QUERY}";
                      }
                      {
                        title = "NixOS";
                        shortcut = "!nix";
                        url = "https://search.nixos.org/packages?query={QUERY}";
                      }
                      {
                        title = "YouTube";
                        shortcut = "!yt";
                        url = "https://www.youtube.com/results?search_query={QUERY}";
                      }
                      {
                        title = "Crates";
                        shortcut = "!crate";
                        url = "https://crates.io/search?q={QUERY}";
                      }
                      {
                        title = "NPM";
                        shortcut = "!npm";
                        url = "https://www.npmjs.com/search?q={QUERY}";
                      }
                    ];
                  }

                  # Service health monitoring
                  {
                    type = "monitor";
                    title = "Services";
                    cache = "1m";
                    sites = [
                      {
                        title = "Netdata";
                        url = "http://localhost:19999";
                        icon = "si:netdata";
                      }
                      {
                        title = "Grafana";
                        url = "http://localhost:3001";
                        icon = "si:grafana";
                      }
                      {
                        title = "Prometheus";
                        url = "http://localhost:9090";
                        icon = "si:prometheus";
                      }
                      {
                        title = "Scrutiny";
                        url = "http://localhost:8080";
                        icon = "mdi:harddisk";
                      }
                      {
                        title = "ActivityWatch";
                        url = "http://localhost:5600";
                        icon = "mdi:clock-check-outline";
                      }
                    ];
                  }

                  # Docker containers
                  {
                    type = "docker-containers";
                    format-container-names = true;
                  }
                ];
              }

              # CENTER MAIN
              {
                size = "full";
                widgets = [
                  # Hacker News
                  {
                    type = "hacker-news";
                    limit = 10;
                    collapse-after = 5;
                    extra-sort-by = "engagement";
                  }

                  # YouTube feeds
                  {
                    type = "videos";
                    title = "YouTube";
                    style = "grid-cards";
                    channels = [
                      # Fireship
                      "UCsBjURrPoezykLs9EqgamOA"
                      # ThePrimeagen
                      "UCUyeluBRhGPCW4rPe_UvBZQ"
                      # No Boilerplate
                      "UCc0YbtMkRdhcqwhu3Oad-lw"
                      # Beyond Fireship
                      "UC2Xd-TjJByJyK2w1zNwY0zQ"
                      # Better Stack
                      "UCkVfrGwV-iG9bSsgCbrNPxQ"
                      # codingjerk
                      "UCFPTbsXLqWLHcXosYYw3D6Q"
                      # PwnFunction
                      "UCW6MNdOsqv2E9AjQkv9we7A"
                      # ByteByteGo
                      "UCZgt6AzoyjslHTC9dz0UoTw"
                      # Dreams of Code
                      "UCWQaM7SpSECp9FELz-cHzuQ"
                      # Seytonic
                      "UCW6xlqxSY3gGur4PkGPEUeA"
                      # Bubble Brian
                      "UCvF3C7NCZBHuE9iJvmsxO3w"
                      # bigboxSWE
                      "UC5--wS0Ljbin1TjWQX6eafA"
                      # Code to the Moon
                      "UCjREVt2ZJU8ql-NC9Gu-TJw"
                      # Mental Outlaw
                      "UC7YOGHUfC1Tb6E4pudI9STA"
                      # Vimjoyer
                      "UC_zBdZ0_H_jn41FDRG7q4Tw"
                    ];
                  }
                ];
              }

              # RIGHT SIDEBAR
              {
                size = "small";
                widgets = [
                  # System stats
                  {
                    type = "server-stats";
                    servers = [
                      {
                        type = "local";
                        name = "PC";
                        mountpoints = {
                          "/" = {
                            name = "Root";
                          };
                          "/home" = {
                            name = "Home";
                          };
                        };
                      }
                    ];
                  }

                  # Bookmarks
                  {
                    type = "bookmarks";
                    groups = [
                      {
                        title = "Quick";
                        links = [
                          {
                            title = "Proton Mail";
                            url = "https://mail.proton.me/u/1/inbox";
                            icon = "si:protonmail";
                          }
                          {
                            title = "GitHub";
                            url = "https://github.com";
                            icon = "si:github";
                          }
                          {
                            title = "X";
                            url = "https://x.com/home";
                            icon = "si:x";
                          }
                          {
                            title = "SimpleLogin";
                            url = "https://app.simplelogin.io/dashboard/";
                            icon = "mdi:shield-lock-outline";
                          }
                          {
                            title = "Codeberg";
                            url = "https://codeberg.org/";
                            icon = "si:codeberg";
                          }
                          {
                            title = "YouTube";
                            url = "https://www.youtube.com/";
                            icon = "si:youtube";
                          }
                          {
                            title = "Reddit";
                            url = "https://www.reddit.com/";
                            icon = "si:reddit";
                          }
                        ];
                      }
                      {
                        title = "Dev";
                        color = "43 59 81"; # Gruvbox yellow
                        links = [
                          {
                            title = "DevDocs";
                            url = "https://devdocs.io/";
                          }
                          {
                            title = "Excalidraw";
                            url = "https://excalidraw.com/";
                          }
                          {
                            title = "DEV Community";
                            url = "https://dev.to/";
                          }
                        ];
                      }
                    ];
                  }

                  # GitHub releases
                  {
                    type = "releases";
                    title = "Releases";
                    show-source-icon = true;
                    limit = 6;
                    collapse-after = 3;
                    repositories = [
                      "rust-lang/rust"
                      "YaLTeR/niri"
                      "neovim/neovim"
                      "glanceapp/glance"
                    ];
                  }
                ];
              }
            ];
          }
        ];
      };
    };

    systemd.services.glance.serviceConfig.SupplementaryGroups = [ "docker" ];
  };
}
