{ dockerTools, lib, fetchurl, imagePrefix }:
let
  pluginVersion = "15.0.2-1";

  kcPlugin = fetchurl {
    url    = "https://github.com/UQ-RCC/hpcportal-keycloak-extension/releases/download/${pluginVersion}/hpcportal-keycloak-extension-${pluginVersion}.jar";
    sha256 = "0yyfgqv2g7vk38b7687gr0hksg9yzv228j55izbiy2pkvfk0jm8x";
  };
in
dockerTools.buildLayeredImage {
  name = "${imagePrefix}/keycloak-rcc";
  tag  = "15.0.2";

  # jboss/keycloak:15.0.2
  fromImage = dockerTools.pullImage {
    imageName   = "jboss/keycloak";
    imageDigest = "sha256:d8ed1ee5df42a178c341f924377da75db49eab08ea9f058ff39a8ed7ee05ec93";
    sha256      = "16av7vinn884gnq91a45ny1jx7aqjqwki1ja6b1gk6hg0g79hkd5";
  };

  fakeRootCommands = ''
    mkdir -p opt/jboss/keycloak/standalone/deployments
    cp ${kcPlugin} opt/jboss/keycloak/standalone/deployments/$(stripHash ${kcPlugin})
    chmod 0664 opt/jboss/keycloak/standalone/deployments/$(stripHash ${kcPlugin})
    chown -R 1000:0 opt/jboss
  '';

  # Nix doesn't preserve this for some reason...
  config = {
    User       = "1000";
    Entrypoint = ["/opt/jboss/tools/docker-entrypoint.sh"];
    Cmd        = ["-b" "0.0.0.0"];
    ExposedPorts = {
      "8080" = {};
      "8443" = {};
    };
  };
}
