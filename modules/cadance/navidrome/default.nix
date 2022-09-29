##
# CADANCE Module to run multiple containerised Navidrome instances.
# - Music libraries are expected to be host-accessible, so a
#   matching user/group is required.
##
{ config, pkgs, lib, ... }:
let
  cfg    = config.cadance.containers.navidrome;
  format = pkgs.formats.json {};
  httpPort = 4533;

  makeContainer = instance: let
    container = pkgs.callPackage ../../containers/navidrome {
      navidrome = instance.package;
    };

    configFile = format.generate "navidrome.json" (instance.extraSettings // {
      Address                 = "0.0.0.0";
      Port                    = httpPort;
      MusicFolder             = instance.internalMusicMountPath;
      DataFolder              = "/data";
      BaseUrl                 = instance.baseUrl;
      ScanSchedule            = 0;
      ImageCacheSize          = "100MB";
      TranscodingCacheSize    = "2GB";
      EnableTranscodingConfig = false;

      UILoginBackgroundUrl    = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAMgAAADICAIAAAAiOjnJAAAABGdBTUEAALGPC/xhBQAAAiJJREFUeF7t0IEAAAAAw6D5Ux/khVBhwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDBgwIABAwYMGDDwMDDVlwABBWcSrQAAAABJRU5ErkJggg==";
      DefaultTheme            = "Spotify-ish";

      EnableUserEditing       = true;

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
    });
  in {
    image     = "${container.imageName}:${container.imageTag}";
    imageFile = container.outPath;

    user = "${toString cfg.uid}:${toString cfg.gid}";

    environment = {
      ND_CONFIGFILE = "/navidrome.json";
    };

    volumes = [
      "${configFile}:/navidrome.json:ro"
      "${instance.dataDir}:/data:rw"
      "${instance.musicPath}:${instance.internalMusicMountPath}:ro"
    ];

    ports = [
      "127.0.0.1:${toString instance.port}:${toString httpPort}"
    ];
  };

  makeVirtualHost = name: instance: {
    "${instance.virtualHost}" = {
      locations.${instance.baseUrl} = {
        priority = instance.priority;
        proxyPass = "http://localhost:${toString instance.port}";
        extraConfig = ''
          proxy_buffering       off;
          proxy_connect_timeout 60m;
          proxy_read_timeout    60m;
          proxy_send_timeout    60m;
        '';
      };
    };
  };

  recursiveMerge = with lib; attrList:
    let f = attrPath:
      zipAttrsWith (n: values:
        if tail values == []
          then head values
        else if all isList values
          then unique (concatLists values)
        else if all isAttrs values
          then f (attrPath ++ [n]) values
        else last values
      );
    in f [] attrList;
in {
  options.cadance.containers.navidrome = with lib; {
    enable = mkOption {
      default     = false;
      type        = types.bool;
      description = "Enable Navidrome container";
    };

    instances = mkOption {
      default = {};
      type = with types; attrsOf(submodule(name: {
        options = {
          virtualHost = mkOption {
            type = types.str;
          };

          port = mkOption {
            type = with types; ints.between 1 65536;
          };

          baseUrl = mkOption {
            type = types.str;
          };

          priority = mkOption {
            type = types.int;
          };

          musicPath = mkOption {
            type = types.str;
          };

          dataDir = mkOption {
            type    = types.str;
            default = "/data";
          };

          package = mkPackageOption pkgs "navidrome" { };

          internalMusicMountPath = mkOption {
            type    = types.str;
            default = "/music";
            visible = false;
          };

          extraSettings = mkOption {
            type = with types; attrsOf (oneOf [ bool int str ]);
            default = {};
          };
        };
      }));
    };

    containerPrefix = mkOption {
      type        = types.str;
      default     = "navidrome";
    };

    uid = mkOption {
      type = types.int;
    };

    gid = mkOption {
      type = types.int;
    };

    extraSettings = mkOption {
      type = with types; attrsOf (oneOf [ bool int str ]);
      default = {};
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers = lib.mapAttrs' (
      k: v: lib.nameValuePair ("${cfg.containerPrefix}-${k}") (makeContainer v)
    ) cfg.instances;

    services.nginx.virtualHosts = recursiveMerge (lib.mapAttrsToList makeVirtualHost cfg.instances);

    users.groups.navidrome.gid = cfg.gid;
    users.users.navidrome = {
      isSystemUser = true;
      uid          = cfg.uid;
      group        = "navidrome";
    };
  };
}
