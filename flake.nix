{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nixpkgs, home-manager, ... }: rec {
    formatter.aarch64-linux = nixpkgs.legacyPackages.aarch64-linux.nixpkgs-fmt;
    nixosConfigurations.main-nix-0 = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      specialArgs = {
        # inherit inputs self;
        # inputs = "aa";
        # clib = import ./funcs.nix { lib = nixpkgs.lib; };
      };
      modules = [
        ./configuration.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;

          home-manager.users.root = import ./home/root.nix;
          home-manager.users.reverseproxy = import ./home/reverseproxy.nix;
          home-manager.users.grafana = import ./home/grafana.nix;
          home-manager.users.authentik = import ./home/authentik.nix;
        }
      ];
    };
  };
}
