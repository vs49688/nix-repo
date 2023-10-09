{
  outputs = { self, nixpkgs }: let
    lib = nixpkgs.lib;

    mkNixpkgs = { system }: import self.inputs.nixpkgs {
      inherit system;
      overlays = [ self.overlays.default ];
      config.allowUnfree = true;
    };
  in {
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

    packages = let
      mkFlakePackages = { system }: rec {
        inherit (mkNixpkgs { inherit system; })
          awesfx
          crocutils
          extract-drs
          extract-glb
          pimidid
          jdownloader
          mailpump
          mangostwo-server
          mangostwo-database
          # zane-scripts
          offzip
          _010editor
          vgmtrans
          revive
          raftools
          unifi-backup-decrypt
          kafkactl
          navidrome-mbz
          hg659-voip-password
          solar2
          supermeatboy
          xash3d-fwgs
          xash3d-fwgs-full
          croc-lotg
          mongodb_3_6-bin

          rom-parser
          xboomer

          linearmouse-bin
          scroll-reverser-bin
          hammerspoon-bin

          nimrod-portal-backend
          portal-client
          portal-client_1_0_4
          portal-resource-server
          nimrodg-agent
          nimrun
          nimptool-legacy
          ims2tif
          imsmeta
          nimrod-portal
          ipp_1_1
        ;
      };

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
