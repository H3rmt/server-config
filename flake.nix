{
  description = "Server flake (Headscale + K3s cluster)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix-rekey = {
      url = "github:oddlama/agenix-rekey";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, flake-parts, agenix, agenix-rekey, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" ];

      perSystem = { pkgs, system, ... }: {
        formatter = pkgs.nixfmt-tree;

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            fzf
            micro
            agenix-rekey.packages.${system}.default
          ];
        };
      };

      flake = {
        nixosConfigurations = {
          raspi-1 = nixpkgs.lib.nixosSystem {
            system = "aarch64-linux";
            specialArgs = { inherit inputs; };
            modules = [
              ./secrets.nix
              ./base.nix
              ./raspi-1.nix
              ./k3s-worker.nix
              agenix.nixosModules.default
              agenix-rekey.nixosModules.default
            ];
          };

          ovh-1 = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = { inherit inputs; };
            modules = [
              ./secrets.nix
              ./base.nix
              ./ovh-1.nix
              ./k3s-root.nix
              agenix.nixosModules.default
              agenix-rekey.nixosModules.default
            ];
          };
        };

        agenix-rekey = agenix-rekey.configure {
          userFlake = self;
          nixosConfigurations = self.nixosConfigurations;
        };
      };
    };
}
