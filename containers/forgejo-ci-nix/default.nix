{ callPackage
, nodejs
, wrangler
, flakeVersion
}:
callPackage ./docker.nix {
  name = "git.vs49688.net/oci/forgejo-ci-nix";
  bundleNixpkgs = false;
  extraPkgs = [
    nodejs   # For Actions
    wrangler # For Cloudflare
  ];
  Labels = {};

  tag = flakeVersion;

  nixConf = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];

    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "cadance.vs49688,net-1:EQcyD9wxzTEdAuqCHbRZUx09b++wE7eA7VZ+7M55npU="
    ];
  };
}