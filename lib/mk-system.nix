{ self }:
rec {
  mkSystem = {
    nixpkgs ? self.inputs.nixpkgs-nixos,
    home-manager ? self.inputs.home-manager,
  }: nixpkgs.lib.nixosSystem {
    modules = [
      home-manager.nixosModules.home-manager
      self.outputs.nixosModules.nixos-base
      self.outputs.nixosModules.default
      self.inputs.impermanence.nixosModules.impermanence
      self.inputs.sops-nix.nixosModules.sops
      ({ config, ... }: let
        lowPrio = nixpkgs.lib.mkOverride 2000;
      in {

        # I hate this shit
        nixpkgs.config.permittedInsecurePackages = [
          "olm-3.2.16"
          "squid-7.0.1"
        ];

        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;

        # Until the modules are updated to use osConfig.
        home-manager.extraSpecialArgs = { hostName = config.networking.hostName; };

        # So nix flake check can pass without overrides.
        settings.primaryUser = lowPrio "nixos";
        settings.users.nixos = lowPrio {
          fullName = "NixOS User";
          username = "nixos";
          email = "nixos@example.com";
          home = "/home/nixos";
          sshKeyPath = "~/.ssh/id_ed25519";
          gpgKeyId = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";
          authorizedKeys = [
            "ssh-ed25519 AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA nixos@SYSTEM"
          ];
        };

        home-manager.users.${config.settings.primaryUser.username}.home.stateVersion = lowPrio "21.11";
      })
    ];
  };
}
