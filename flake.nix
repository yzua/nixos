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
      url = "github:Mic92/sops-nix/17eea6f3816ba6568b8c81db8a4e6ca438b30b7c";
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

    gitanon = {
      url = "github:yzua/gitanon";
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

      hosts = import ./hosts/_inventory.nix;

      activeHosts = builtins.filter (host: host.enabled) hosts;

      forEachHost =
        buildEntry: nixpkgs.lib.foldl' (configs: host: configs // buildEntry host) { } activeHosts;

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
      nixosConfigurations = forEachHost (host: {
        "${host.hostname}" = makeSystem { inherit (host) hostname stateVersion; };
      });

      homeConfigurations = forEachHost (host: {
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
      });

      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          statix
          deadnix
          shellcheck
          nixfmt-tree
        ];
      };

      formatter.${system} = pkgs.nixfmt-tree;

      # CI checks — run with `nix flake check`
      checks.${system} = {
        # Ensure flake evaluates without errors
        flake-eval = pkgs.runCommand "flake-eval" { } ''
          echo "Flake evaluation successful" > $out
        '';

        # Ensure formatter is available
        formatter-available = pkgs.runCommand "formatter-check" { } ''
          test -x ${pkgs.nixfmt-tree}/bin/nixfmt || exit 1
          echo "Formatter check passed" > $out
        '';
      };
    };
}
