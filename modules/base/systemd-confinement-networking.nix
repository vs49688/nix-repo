{ config, pkgs, lib, ... }:
{
  options.systemd.services = with lib; mkOption {
    type = types.attrsOf(types.submodule({ name, config, ... }: {
      options.confinement.configureNetworking = lib.mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc ''
          If set, adds a basic /etc/resolv.conf pointing to 1.1.1.1,
          adds the `cacert` package, and sets SSL_CERT_FILE.
        '';
      };

      config = lib.mkIf config.confinement.configureNetworking {

        confinement.packages = [ pkgs.cacert ];

        environment.SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";

        serviceConfig = {
          # TODO: Force to 1.1.1.1 or something
          BindReadOnlyPaths = [
            "/etc/resolv.conf"
          ];
        };
      };
    }));
  };
}
