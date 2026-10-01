##
# CADANCE Module to run Frigate in a Docker container because
# I don't want its deps crapping-up my system.
##
{ lib, pkgs, config, ... }:
let
  cfg = config.cadance.containers.frigate;
  format = pkgs.formats.yaml { };
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
      default = "https://authelia.example.com/logout?redirect=https://nvr.example.com";
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

    config = lib.mkOption {
      readOnly = true;
      type = types.attrs;
      default = {
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

            role_map = {
              admin = [ "NVR Admins" ];
              viewer = [ "NVR Viewers" ];
            };
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
        record.continuous.days = 28;
        record.motion.days = 28;

        version = "0.18-0";
      };
    };

    configFile = lib.mkOption {
      readOnly = true;
      default = format.generate "config.yaml" cfg.config;
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers.frigate = let
      imageFile = pkgs.dockerTools.pullImage {
        imageName = "git.vs49688.net/oci/frigate";
        imageDigest = "sha256:e07203b1197852cddd18915cc968aa6bbf072200b88030c028f38bbe652e77c4";
        hash = "sha256-ct66/bRy19PsbU4G37iMf/I8zQl6m91dRHePtkw3z7c=";
        finalImageName = "localhost/frigate";
        finalImageTag = "0.18.0";
      };
    in {
      inherit imageFile;

      image = "${imageFile.imageName}:${imageFile.imageTag}";

      volumes = [
        "${cfg.configPath}:/config:rw"
        "${cfg.configFile}:/config/config.yml:ro"
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

    services.caddy.virtualHosts.${cfg.hostName}.extraConfig = ''
      route {
        forward_auth unix//run/authelia/authelia.sock {
          uri /api/authz/forward-auth

          copy_headers Remote-User Remote-Groups Remote-Email Remote-Name
        }

        reverse_proxy http://127.0.0.1:${toString cfg.port} {
          # Stop the Authelia session cookie being passed to Frigate.
          header_up Cookie "authelia_session=[^;]+" "authelia_session=_"

          flush_interval -1
        }
      }
    '';

    networking.firewall.allowedTCPPorts = [ 8555 ];
    networking.firewall.allowedUDPPorts = [ 8555 ];
  };
}
