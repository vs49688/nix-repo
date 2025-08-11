{
  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs;

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence.url = github:nix-community/impermanence;

    nixos-apple-silicon.url = "github:nix-community/nixos-apple-silicon";
    nixos-apple-silicon.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, ... }: let
    overlayPackages = overlay: pkgs: let
      tmpPkgs = (overlay tmpPkgs pkgs);
      packageNames = builtins.attrNames tmpPkgs;
      packageSet = builtins.listToAttrs (builtins.map (u: { name = u; value = pkgs.${u}; }) packageNames);
    in packageSet;

    mkNixpkgs = { system }: import self.inputs.nixpkgs {
      inherit system;
      overlays = [
        self.overlays.default
        self.overlays.mongodb
      ];
      config.allowUnfree = true;
    };
  in {
    overlays = {
      default = final: prev: ((import ./overlay.nix { }) final prev);
      mongodb = import ./mongodb/overlay.nix;
    };

    nixosModules = {
      default = { pkgs, ... }: {
        imports = import ./modules/public.nix;
        nixpkgs.overlays = [ self.overlays.default ];
      };

      cadance = { pkgs, ... }: {
        imports = (import ./modules/public.nix) ++ (import ./modules/cadance);
        nixpkgs.overlays = [ self.overlays.default ];
      };

      settings = import ./modules/settings;

      base = import ./modules/base;

      nixos-base = import ./modules/nixos-base.nix;

      gui6 = import ./modules/gui6.nix;

      devmachine = import ./modules/devmachine;

      ssh-totp = import ./modules/ssh-totp.nix;

      postgres-ensure-roles = import ./modules/postgres-ensure-roles.nix;
    };

    packages = let
      mkFlakePackages = { system }: let
        pkgs = mkNixpkgs { inherit system; };
      in
        (overlayPackages (import ./overlay.nix { asFlake = true; }) pkgs) //
        (overlayPackages self.overlays.mongodb pkgs)
      ;

      mkPackages = { system }: nixpkgs.lib.filterAttrs
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

    containers = let
      pkgs = mkNixpkgs { system = "x86_64-linux"; };
    in pkgs.callPackage ./containers {
      imagePrefix = "ghcr.io/vs49688";
    };

    lib = import ./lib { inherit self; };

    ##
    # Base NixOS Configurations
    # 1. These are extended by my personal configuration.
    # 2. Don't expect them to work without it.
    ##
    nixosConfigurations = let
      baseSystem = self.outputs.lib.mkSystem { };
    in {
      MORNINGSTAR = baseSystem.extendModules {
        modules = [
          ./hosts/morningstar
        ];
      };

      ZAIR = baseSystem.extendModules {
        modules = [
          self.inputs.nixos-apple-silicon.nixosModules.default
          ./hosts/zair
        ];
      };
    };
  };
}
