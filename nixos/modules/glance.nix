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
                    type = "rss";
                    title = "YouTube";
                    style = "horizontal-cards";
                    limit = 12;
                    feeds = [
                      {
                        url = "https://www.youtube.com/feeds/videos.xml?channel_id=UCsBjURrPoezykLs9EqgamOA";
                        title = "Fireship";
                      }
                      {
                        url = "https://www.youtube.com/feeds/videos.xml?channel_id=UCUyeluBRhGPCW4rPe_UvBZQ";
                        title = "ThePrimeagen";
                      }
                      {
                        url = "https://www.youtube.com/feeds/videos.xml?channel_id=UCc0YbtMkRdhcqwhu3Oad-lw";
                        title = "No Boilerplate";
                      }
                      {
                        url = "https://www.youtube.com/feeds/videos.xml?channel_id=UC2Xd-TjJByJyK2w1zNwY0zQ";
                        title = "Beyond Fireship";
                      }
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
                            title = "LinkedIn";
                            url = "https://www.linkedin.com/in/yz/";
                            icon = "si:linkedin";
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
