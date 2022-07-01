{
  outputs = { self, nixpkgs }: let
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
      mkPackages = { system }: {
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

          protobuf3_13

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
    in {
      x86_64-linux = mkPackages { system = "x86_64-linux"; };
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
