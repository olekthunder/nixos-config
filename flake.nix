{
  description = "A very basic flake";

  inputs = {
    home-manager.url = "github:rycee/home-manager";
  };

  outputs = { self, nixpkgs, ... }@inputs: {
    nixosConfigurations.gimli = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {
        inherit inputs;
      };
      modules = [];
    };
  };
}
