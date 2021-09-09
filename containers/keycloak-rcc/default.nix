{ dockerTools, lib, fetchurl }:
let
  pluginVersion = "15.0.2-1";

  kcPlugin = fetchurl {
    url    = "https://github.com/UQ-RCC/hpcportal-keycloak-extension/releases/download/${pluginVersion}/hpcportal-keycloak-extension-${pluginVersion}.jar";
    sha256 = "0yyfgqv2g7vk38b7687gr0hksg9yzv228j55izbiy2pkvfk0jm8x";
  };
in
dockerTools.buildLayeredImage {
  name = "uqrcc/keycloak-rcc";
  tag  = "15.0.2";

  # jboss/keycloak:15.0.2
  fromImage = dockerTools.pullImage {
    imageName   = "jboss/keycloak";
    imageDigest = "sha256:d8ed1ee5df42a178c341f924377da75db49eab08ea9f058ff39a8ed7ee05ec93";
    sha256      = "16av7vinn884gnq91a45ny1jx7aqjqwki1ja6b1gk6hg0g79hkd5";
  };

  extraCommands = ''
    mkdir -p opt/jboss/keycloak/standalone/deployments
    cp ${kcPlugin} opt/jboss/keycloak/standalone/deployments/$(stripHash ${kcPlugin})
    chmod 0664 opt/jboss/keycloak/standalone/deployments/$(stripHash ${kcPlugin})
  '';

  # Nix doesn't preserve this for some reason...
  config.Entrypoint = ["/opt/jboss/tools/docker-entrypoint.sh"];
}