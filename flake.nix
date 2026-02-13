# Entry point: flake-based NixOS + Home Manager configuration.
{
  description = "Personal NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.11";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri.url = "github:sodiboo/niri-flake"; # Do NOT follow nixpkgs — mesa compatibility

    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixcord = {
      url = "github:KaylorBen/nixcord";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      nixpkgs-stable,
      home-manager,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      homeStateVersion = "25.11";
      user = "yz";

      hosts = [
        {
          hostname = "pc";
          stateVersion = "25.11";
        }
        # {
        #   hostname = "laptop";
        #   stateVersion = "25.11";
        # }
      ];

      # Single source of truth for all nixpkgs instances
      pkgConfig = {
        allowUnfree = true;
        allowBroken = false;
        allowInsecure = false;
        allowUnsupportedSystem = false;
      };

      constants = import ./shared/constants.nix;

      pkgs = import nixpkgs {
        inherit system;
        config = pkgConfig;
      };

      pkgsStable = import nixpkgs-stable {
        inherit system;
        config = pkgConfig;
      };

      makeSystem =
        { hostname, stateVersion }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit
              inputs
              stateVersion
              hostname
              user
              pkgsStable
              pkgConfig
              constants
              ;
          };
          modules = [ ./hosts/${hostname}/configuration.nix ];
        };
    in
    {
      nixosConfigurations = nixpkgs.lib.foldl' (
        configs: host:
        configs // { "${host.hostname}" = makeSystem { inherit (host) hostname stateVersion; }; }
      ) { } hosts;

      homeConfigurations = nixpkgs.lib.foldl' (
        configs: host:
        configs
        // {
          "${user}@${host.hostname}" = home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            extraSpecialArgs = {
              inherit
                inputs
                homeStateVersion
                user
                pkgsStable
                constants
                ;
              inherit (host) hostname;
            };
            modules = [
              ./home-manager/home.nix
              inputs.nix-index-database.homeModules.nix-index
            ];
          };
        }
      ) { } hosts;

      formatter.${system} = pkgs.nixfmt-tree;
    };
}
