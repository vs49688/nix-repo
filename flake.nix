{
  outputs = { self, nixpkgs }: {
    overlays = {
      default = final: prev: (import ./overlay.nix final prev);
    };

    nixosModules = {
      default = { pkgs, ... }: {
        imports = import ./modules;
        nixpkgs.overlays = [ self.overlays.default ];
      };

      cadance = { pkgs, ... }: {
        imports = (import ./modules) ++ (import ./modules/cadance);
        nixpkgs.overlays = [ self.overlays.default ];
      };
    };

    nixosModule = self.nixosModules.default;

    containers = let
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        overlays = [ self.overlays.default ];
        config.allowUnfree = true;
      };
    in import ./containers {
      inherit pkgs;
      lib = nixpkgs.lib;
      imagePrefix = "ghcr.io/vs49688";
    };

    hpc = let
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        overlays = [ self.overlays.default ];
        config.allowUnfree = true;
      };
    in import ./hpc {
      inherit pkgs;
      lib = nixpkgs.lib;
    };
  };
}
