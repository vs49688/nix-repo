{
  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs;
    nixpkgs-nixos.url = github:NixOS/nixpkgs/nixos-unstable;

    nixpkgs-cadance.url = "github:NixOS/nixpkgs?ref=e73de5be04e0eff4190a1432b946d469c794e7b4";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs-nixos";
    };

    impermanence = {
      url = github:nix-community/impermanence;
      inputs.nixpkgs.follows = "nixpkgs-nixos";
      inputs.home-manager.follows = "home-manager";
    };

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nixos-hardware.inputs.nixpkgs.follows = "nixpkgs-nixos";

    nixos-apple-silicon.url = "github:nix-community/nixos-apple-silicon";
    nixos-apple-silicon.inputs.nixpkgs.follows = "nixpkgs-nixos";

    nix-darwin.url = "github:nix-darwin/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    # Just after v0.43.0, they forgot to update the version
    docspell.url = "github:eikek/docspell?ref=92160c68726211052e85591ab5e6f783aa5d76b6";
    docspell.inputs.nixpkgs.follows = "nixpkgs-nixos";
    # Because they're not pinning it and I don't want _another_ nixpkgs version.
    docspell.inputs.devshell-tools = {
      url = "github:eikek/devshell-tools";
      inputs.nixpkgs.follows = "nixpkgs-nixos";
    };
  };

  outputs = { self, nixpkgs, ... }: let
    flakeVersion = "${self.lastModifiedDate}-${if (self ? shortRev) then self.shortRev else self.dirtyShortRev}";

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
        imports = (import ./modules/public.nix) ++ ((import ./modules/cadance) {
          docspell = self.inputs.docspell;
        });

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
      mkFlakePackages = { pkgs }:
        (overlayPackages (import ./overlay.nix { asFlake = true; }) pkgs) //
        (overlayPackages self.overlays.mongodb pkgs)
      ;

      mkPackages = { system }: let
        pkgs = mkNixpkgs { inherit system; };
      in nixpkgs.lib.filterAttrs
        (name: pkg:
          nixpkgs.lib.meta.availableOn pkgs.stdenv.hostPlatform pkg
        )
        (mkFlakePackages { inherit pkgs; })
      ;

    in {
      x86_64-linux   = mkPackages { system = "x86_64-linux";   };
      aarch64-linux  = mkPackages { system = "aarch64-linux";  };
      aarch64-darwin = mkPackages { system = "aarch64-darwin"; };
    };

    legacyPackages.x86_64-linux = let
      pkgs = self.inputs.nixpkgs.legacyPackages.x86_64-linux;
    in {
      xash3d-fwgs = pkgs.callPackage ./pkgs/xash3d-fwgs { };
    };

    containers = let
      pkgs = mkNixpkgs { system = "x86_64-linux"; };
    in pkgs.callPackage ./containers {
      inherit flakeVersion;

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
      AVALON = baseSystem.extendModules {
        modules = [
          ./hosts/avalon
        ];
      };

      CADANCE = let
        baseSystem = self.outputs.lib.mkSystem {
          nixpkgs = self.inputs.nixpkgs-cadance;
        };
      in baseSystem.extendModules {
        modules = [
          self.inputs.sops-nix.nixosModules.sops
          ./hosts/cadance
          (import ./modules/cadance/docspell.nix {
            docspell = self.inputs.docspell;
          })
        ];
      };

      CAPRICA = baseSystem.extendModules {
        modules = [
          ./hosts/caprica
          ./modules/personal.nix
        ];
      };

      MORNINGSTAR = baseSystem.extendModules {
        modules = [
          ./hosts/morningstar
          ./modules/personal.nix
        ];
      };

      TWILYSPARKLE = baseSystem.extendModules {
        modules = [
          self.inputs.nixos-hardware.nixosModules.dell-xps-15-9550-nvidia
          ./hosts/twilysparkle
          ./modules/personal.nix
        ];
      };

      ZAIR = baseSystem.extendModules {
        modules = [
          self.inputs.nixos-apple-silicon.nixosModules.default
          ./hosts/zair
          ./modules/personal.nix
        ];
      };

      ANGELUS = baseSystem.extendModules {
        modules = [
          self.inputs.nixos-apple-silicon.nixosModules.default
          ./hosts/angelus
          ./modules/personal.nix
        ];
      };
    };

    systems = builtins.mapAttrs (k: v: v.config.system.build.toplevel) self.outputs.nixosConfigurations;

    ##
    # I actively despise this shit OS.
    # How do they manage to make it so f***ing user-unfriendly?
    ##
    darwinConfigurations."Zanes-MacBook-Air" = self.inputs.nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      modules = [
        self.inputs.home-manager.darwinModules.home-manager
        ./darwin/hosts/zanes-macbook-air
      ];
    };

    darwinConfigurations."ANGELUS" = self.inputs.nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      modules = [
        self.inputs.home-manager.darwinModules.home-manager
        ./darwin/hosts/angelus
      ];
    };
  };
}
