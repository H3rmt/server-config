{
  description = "Server flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nixpkgs, home-manager, agenix, ... }: {
    formatter.aarch64-linux = nixpkgs.legacyPackages.aarch64-linux.nixpkgs-fmt;
    nixosConfigurations = {
      main-nix-1 = nixpkgs.lib.nixosSystem ({
        system = "aarch64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          home-manager.nixosModules.home-manager
          agenix.nixosModules.default
          ./shared/vars.nix
          ./shared/baseconfig.nix
          ./main-nix-1/configuration.nix
        ];
      });
      main-nix-2 = nixpkgs.lib.nixosSystem ({
        system = "aarch64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          home-manager.nixosModules.home-manager
          agenix.nixosModules.default
          ./shared/vars.nix
          ./shared/baseconfig.nix
          ./main-nix-2/configuration.nix
        ];
      });
      raspi-1 = nixpkgs.lib.nixosSystem ({
        system = "aarch64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          home-manager.nixosModules.home-manager
          agenix.nixosModules.default
          ./shared/vars.nix
          ./shared/baseconfig.nix
          ./raspi-1/configuration.nix
        ];
      });
    };
  };
}
