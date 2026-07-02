##
# CADANCE Module to run Frigate in a Docker container because
# I don't want its deps crapping-up my system.
##
{ lib, pkgs, config, ... }:
let
  cfg = config.cadance.containers.frigate;
  format = pkgs.formats.yaml { };

  configFile = format.generate "config.yaml" ({
    tls.enabled = false; # Handled by the reverse proxy
    mqtt.enabled = false;

    auth.enabled = false;
    # auth.cookie_secure = false;

    proxy = {
      default_role = "viewer";
      logout_url = cfg.logoutUrl;
      header_map = {
        user = "Remote-User";
        role = "Remote-Groups";
      };
    };

    detect.enabled = false; # FIXME: Figure out if possible.

    # Record _with_ audio by default.
    ffmpeg.output_args.record = "preset-record-generic-audio-aac";

    # WebRTC needs Opus audio, transcode.
    go2rtc.streams = lib.mergeAttrsList (lib.mapAttrsToList (name: value: {
      "${name}_main" = [
        value.mainUrl
        "ffmpeg:${name}_main#audio=opus"
      ];

      "${name}_sub" = [
        value.subUrl
        "ffmpeg:${name}_sub#audio=opus"
      ];
    }) cfg.cameras);

    go2rtc.webrtc.candidates = cfg.webrtcCandidates;

    cameras = builtins.mapAttrs (name: value: {
      enabled = value.enabled;
      ffmpeg = {
        hwaccel_args = "preset-vaapi";
        inputs = [
          {
            path = "rtsp://127.0.0.1:8554/${name}_main";
            input_args = "preset-rtsp-restream";
            roles = [ "record" ];
          }
        ];
      };
      live.streams."${name}_sub" = "${name}_sub";

      # onvif = value.onvif;
    }) cfg.cameras;

    birdseye.enabled = true;
    birdseye.mode = "continuous";

    snapshots.enabled = true;
    snapshots.timestamp = false; # Cameras do this.

    ui.timezone = config.time.timeZone;
    ui.time_format = "browser";

    record.enabled = true;
    record.sync_recordings = true;
    record.retain.days = 28;
    record.retain.mode = "all";

    version = "0.16-0";
  });
in
{
  options.cadance.containers.frigate = with lib; {
    enable = mkEnableOption "Enable Frigate container";

    port = mkOption {
      type = with types; ints.between 1 65536;
    };

    configPath = mkOption {
      type = types.str;
    };

    mediaPath = mkOption {
      type = types.str;
    };

    shmSize = mkOption {
      # python -c 'print("{:.2f}MB".format(((3840 * 2160 * 1.5 * 9 + 270480) / 1048576) * 4 + 30))'
      type = types.str;
    };

    hostName = mkOption {
      type = types.str;
    };

    logoutUrl = mkOption {
      type = types.str;
      example = "https://authelia.example.com/logout?redirect=https://nvr.example.com";
    };

    webrtcCandidates = mkOption {
      type = types.listOf types.str;
      default = [];
    };

    cameras = mkOption {
      default = {};

      type = types.attrsOf(types.submodule {
        options = {
          enabled = mkEnableOption "Enable camera";

          mainUrl = mkOption {
            type = types.str;
          };

          subUrl = mkOption {
            type = types.str;
          };

          onvif = mkOption {
            default = null;

            type = types.nullOr (types.submodule {
              options = {
                host = mkOption {
                  type = types.str;
                };

                user = mkOption {
                  type = types.str;
                };

                password = mkOption {
                  type = types.str;
                };

                port = mkOption {
                  type = types.int;
                };
              };
            });
          };
        };
      });
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers.frigate = let
      imageFile = pkgs.dockerTools.pullImage {
        # imageName = "ghcr.io/blakeblackshear/frigate";
        # imageDigest = "sha256:1f8dbaaa4c7c2855c2aef711842d13b0c20bfdc3f28ad88faf66aa1bc219b108";

        # Digest changes due to https://github.com/docker/cli/issues/6812
        imageName = "git.vs49688.net/oci/frigate";
        imageDigest = "sha256:0133187256e5f275e42d73ba5f8967c1768c5978540242eb39ee9ce17832f0be";
        hash = "sha256-ms0AiKXkzUiTLOj/67kGI773vXRT4BbLg2I8nPKYFak=";
        finalImageName = "localhost/frigate";
        finalImageTag = "0.16.4";
      };
    in {
      inherit imageFile;

      image = "${imageFile.imageName}:${imageFile.imageTag}";

      volumes = [
        "${cfg.configPath}:/config:rw"
        "${configFile}:/config/config.yml:ro"
        "${cfg.mediaPath}:/media/frigate:rw"
        "${pkgs.go2rtc}/bin/go2rtc:/config/go2rtc:ro"
      ];

      ports = [
        "127.0.0.1:${toString cfg.port}:8971"
        "8555:8555/tcp"
        "8555:8555/udp"

      ];

      extraOptions = [
        "--shm-size=${cfg.shmSize}"
        "--mount" "type=tmpfs,target=/tmp/cache,tmpfs-size=1000000000"
      ];

      devices = [
        "/dev/dri/renderD128:/dev/dri/renderD128"
      ];

      environment = {
        LIBVA_DRIVER_NAME = "radeonsi";
      };
    };

    systemd.services."${config.virtualisation.oci-containers.backend}-frigate" = {
      unitConfig.RequiresMountsFor = [ cfg.mediaPath ];
      restartIfChanged = false;
    };

    ##
    # Can't use forward_auth because Frigate demands either "viewer" or "admin" roles,
    # and Authelia doesn't allow rewriting them.
    # Remove once https://github.com/blakeblackshear/frigate/pull/19758 hits stable
    ##
    services.caddy.virtualHosts.${cfg.hostName}.extraConfig = ''
      reverse_proxy unix//run/authelia/authelia.sock {
        method GET

        rewrite /api/authz/forward-auth

        header_up X-Forwarded-Method {method}
        header_up X-Forwarded-Uri {uri}

        @good status 2xx
        handle_response @good {
          @admins expression `{rp.header.Remote-Groups}.contains("NVR Admins")`
          request_header @admins +Remote-Groups "admin"

          @viewers expression `{rp.header.Remote-Groups}.contains("NVR Viewers")`
          request_header @viewers +Remote-Groups "viewer"

          @neither expression `!({rp.header.Remote-Groups}.contains("NVR Admins") || {rp.header.Remote-Groups}.contains("NVR Viewers"))`
          handle @neither {
              respond "Forbidden" 403
          }

          request_header Remote-User {rp.header.Remote-User}
          request_header Remote-Name {rp.header.Remote-Name}
          request_header Remote-Email {rp.header.Remote-Email}
          # request_header X-OG-Remote-Groups {rp.header.Remote-Groups}
        }
      }

      reverse_proxy http://127.0.0.1:${toString cfg.port} {
        # Stop the Authelia session cookie being passed to Frigate.
        header_up Cookie "authelia_session=[^;]+" "authelia_session=_"

        flush_interval -1
      }
    '';

    networking.firewall.allowedTCPPorts = [ 8555 ];
    networking.firewall.allowedUDPPorts = [ 8555 ];
  };
}
