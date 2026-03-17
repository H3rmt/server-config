{
  description = "Server flake";
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
  outputs =
    inputs@{
      self,
      nixpkgs,
      flake-parts,
      agenix,
      agenix-rekey,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.agenix-rekey.flakeModule
      ];
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      perSystem =
        {
          pkgs,
          config,
          system,
          ...
        }:
        {
          formatter = pkgs.nixfmt-tree;
          devShells.default = pkgs.mkShell {
            nativeBuildInputs = [ config.agenix-rekey.package ];
            packages = with pkgs; [
              fzf
              k9s
              micro
              wireguard-tools
            ];
          };
        };
      flake = {
        nixosConfigurations = {
          raspi-1 = nixpkgs.lib.nixosSystem {
            system = "aarch64-linux";
            specialArgs = { inherit inputs; };
            modules = [
              ./config.nix
              ./secrets.nix
              ./base.nix
              ./raspi-1.nix
              agenix.nixosModules.default
              agenix-rekey.nixosModules.default
            ];
          };
          ovh-1 = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = { inherit inputs; };
            modules = [
              ./config.nix
              ./secrets.nix
              ./base.nix
              ./ovh-1/index.nix
              agenix.nixosModules.default
              agenix-rekey.nixosModules.default
            ];
          };
          home-1 = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = { inherit inputs; };
            modules = [
              ./config.nix
              ./secrets.nix
              ./base.nix
              ./home-1/index.nix
              agenix.nixosModules.default
              agenix-rekey.nixosModules.default
            ];
          };
        };
      };
    };
}
