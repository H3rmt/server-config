{
  description = "Server flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nixpkgs, home-manager, agenix, ... }: {
    formatter.aarch64-linux = nixpkgs.legacyPackages.aarch64-linux.nixpkgs-fmt;
    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixpkgs-fmt;
    nixosConfigurations = {
      main-nix-1 = nixpkgs.lib.nixosSystem ({
        system = "aarch64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          agenix.nixosModules.default
          ./shared/config.nix
          ./main-nix-1/configuration.nix
        ];
      });
      main-nix-2 = nixpkgs.lib.nixosSystem ({
        system = "aarch64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          agenix.nixosModules.default
          ./shared/config.nix
          ./main-nix-2/configuration.nix
        ];
      });
      raspi-1 = nixpkgs.lib.nixosSystem ({
        system = "aarch64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./base.nix
          ./raspi-1.nix
          ./k3s-control.nix
        ];
      });
      ovh-1 = nixpkgs.lib.nixosSystem ({
        system = "amd64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./base.nix
          ./ovh-1.nix
          ./k3s-worker.nix
        ];
      });
    };
  };
}
