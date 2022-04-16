{
  outputs = { self }: {
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
  };
}
