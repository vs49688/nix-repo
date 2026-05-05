{ buildGoModule, fetchFromForgejo }:
buildGoModule(finalAttrs: {
  pname = "xash-admin";
  version = "1.0.1";

  src = fetchFromForgejo {
    domain = "git.vs49688.net";
    owner = "zane";
    repo = "xash-admin";
    rev = "v${finalAttrs.version}";
    hash = "sha256-09D4fM70t9NfxG+TslMfYaMBWFIuLwLXZA/kjtbAMqM=";
  };

  vendorHash = null;

  ldflags = [
    "-s" "-w"
    "-extldflags=-static"

    "-X git.vs49688.net/zane/xash-admin/config.AppVersion=v${finalAttrs.version}"
  ];
})
