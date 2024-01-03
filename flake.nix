{
  outputs = { self, nixpkgs }: let
    lib = nixpkgs.lib;

    overlayPackages = overlay: pkgs: let
      packageNames = builtins.attrNames (overlay null null);
      packageSet = builtins.listToAttrs (builtins.map (u: { name = u; value = pkgs.${u}; }) packageNames);
    in packageSet;

    mkNixpkgs = { system }: import self.inputs.nixpkgs {
      inherit system;
      overlays = [
        self.overlays.default
        self.overlays.rcc
      ];
      config.allowUnfree = true;
    };
  in {
    overlays = {
      default = final: prev: (import ./overlay.nix final prev);
      rcc = import ./rcc/overlay.nix;
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

    packages = let
      mkFlakePackages = { system }: let
        pkgs = mkNixpkgs { inherit system; };
      in
        (overlayPackages self.overlays.default pkgs) //
        (overlayPackages self.overlays.rcc pkgs)
      ;

      mkPackages = { system }: lib.filterAttrs
        (name: pkg:
          pkg?meta && pkg.meta?platforms && (builtins.elem system pkg.meta.platforms)
        )
        (mkFlakePackages { inherit system; })
      ;

    in {
      x86_64-linux   = mkPackages { system = "x86_64-linux";   };
      aarch64-linux  = mkPackages { system = "aarch64-linux";  };
      aarch64-darwin = mkPackages { system = "aarch64-darwin"; };
      x86_64-darwin  = mkPackages { system = "x86_64-darwin";  };
    };

    nixosModule = self.nixosModules.default;

    containers = let
      pkgs = mkNixpkgs { system = "x86_64-linux"; };
    in pkgs.callPackage ./containers {
      imagePrefix = "ghcr.io/vs49688";
    };

    hpc = let
      pkgs = mkNixpkgs { system = "x86_64-linux"; };
    in pkgs.callPackage ./hpc { };
  };
}
