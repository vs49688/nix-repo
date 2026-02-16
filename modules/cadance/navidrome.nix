{ config, pkgs, lib, ... }:
let
  cfg = config.cadance.navidrome;
in
{
  options.cadance.navidrome = with lib; {
    enable = mkEnableOption "Enable CADANCE Navidrome configuration";

    musicMountPath = mkOption {
      type = types.str;
    };

    virtualHost = mkOption {
      type = types.str;
    };

    environmentFile = mkOption {
      type = types.str;
    };
  };

  config = lib.mkIf cfg.enable {
    services.navidrome = {
      enable = true;

      user = "navidrome";
      group = "navidrome";

      environmentFile = cfg.environmentFile;

      settings = {
        FFmpegPath              = "${pkgs.ffmpeg-for-navidrome}/bin/ffmpeg";

        Address                 = "unix:/run/navidrome/navidrome.sock";
        UnixSocketPerm          = "0660";
        MusicFolder             = "${cfg.musicMountPath}/music";
        DataFolder              = "/var/lib/navidrome";
        BaseUrl                 = "";
        ScanSchedule            = 0;
        ImageCacheSize          = "100MB";
        TranscodingCacheSize    = "2GB";
        EnableTranscodingConfig = false;

        UILoginBackgroundUrl    = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAMgAAADICAIAAAAiOjnJAAAABGdBTUEAALGPC/xhBQAAAiJJREFUeF7t0IEAAAAAw6D5Ux/khVBhwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDDwMDDVlwABBWcSrQAAAABJRU5ErkJggg==";
        DefaultTheme            = "Spotify-ish";

        EnableUserEditing       = true; # Need to keep this on so the user can edit their Subsonic passwords.

        ##
        # Disable everything  external:
        # - there's talk of strange folk abroad. Can't be too careful
        ##
        GATrackingID            = "";
        EnableGravatar          = false;
        "LastFM.Enabled"        = false;
        "LastFM.ApiKey"         = "";
        "LastFM.Secret"         = "";
        "LastFM.Language"       = "en";
        "Spotify.ID"            = "";
        "Spotify.Secret"        = "";
        "ListenBrainz.Enabled"  = false;
        EnableExternalServices  = false;
        EnableInsightsCollector = false;

        "Prometheus.Enabled" = true;
        "Prometheus.MetricsPath" = "/metrics";

        ReverseProxyWhitelist = "@";

        EnableSharing = true;
      };
    };

    systemd.services.navidrome.unitConfig.RequiresMountsFor = [
      cfg.musicMountPath
    ];

    users.groups.navidrome.members = [ config.services.caddy.group ];

    services.caddy.virtualHosts.${cfg.virtualHost}.extraConfig = lib.mkForce ''
      handle /metrics {
        respond 403
      }

      forward_auth unix//run/authelia/authelia.sock {
        uri /api/authz/forward-auth

        # Navidrome only uses this.
        copy_headers Remote-User
      }

      reverse_proxy unix//run/navidrome/navidrome.sock
    '';
  };
}
