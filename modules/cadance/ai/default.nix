{ lib, utils, config, pkgs, ... }:
let
  cfg = config.cadance.ai;

  jsonFormat = pkgs.formats.json { };
  yamlFormat = pkgs.formats.yaml { };

  ##
  # `store` is OpenAI's server-side retention switch, and anthropic, xai and
  # fireworks have no equivalent for it: litellm refuses the whole request over
  # one rather than ignore it. Name it here so the proxy translates, and leave
  # every other unknown parameter failing loudly.
  ##
  dropForeignParams = [ "store" ];

  ##
  # A top-level cache_control asks Claude for automatic caching: one breakpoint
  # slot, placed at the last cacheable block and moved forward as the
  # conversation grows. Injection points would instead pin two of them to blocks
  # the proxy picked, on requests whose clients may have placed their own -- and
  # chat completions has no syntax with which to ask, so this is also the only
  # way to cache for those clients at all.
  ##
  makeAnthropicModel = name: {
    model_name = name;
    litellm_params = {
      model = "anthropic/${name}";
      api_key = "os.environ/ANTHROPIC_API_KEY";
      cache_control = { type = "ephemeral"; };
      additional_drop_params = dropForeignParams;
    };
  };

  ##
  # The model string is the cost-map key, and the proxy describes and bills a
  # deployment from that record. "openai/responses/<name>" is not a key, so the
  # Responses hop left every one of these without a context window, capability
  # flags or a rate -- and clients asking for /v1/responses reach it anyway.
  ##
  makeOpenAIModel = name: {
    model_name = name;
    litellm_params = {
      model = "openai/${name}";
      api_key = "os.environ/OPENAI_API_KEY";
      store = false;
    };
  };
in
{
  options.cadance.ai = with lib; {
    enable = mkEnableOption "Enable CADANCE AI";

    hostName = mkOption {
      type = types.str;
      example = "chat.example.com";
    };

    enableOpenAIModels = mkOption {
      type = types.bool;
    };

    enableAnthropicModels = mkOption {
      type = types.bool;
    };

    enableXAIModels = mkOption {
      type = types.bool;
    };

    enableDeepSeekModels = mkOption {
      type = types.bool;
    };

    openWebUIEnvironmentFile = mkOption {
      type = types.str;
    };

    litellmEnvironmentFile = mkOption {
      type = types.str;
    };

    litellmExtraModels = mkOption {
      type = types.listOf yamlFormat.type;
    };

    oauthClientId = mkOption {
      type = types.str;
      example = "00000000-0000-0000-0000-000000000000";
    };

    oauthProviderUrl = mkOption {
      type = types.str;
      example = "https://auth.example.com/.well-known/openid-configuration";
    };

    oauthProviderName = mkOption {
      type = types.str;
      example = "auth.example.com";
    };

    kokoroTTS = mkOption {
      default = {
        port = 8880;
      };
      type = types.submodule {
        options = {
          port = mkOption {
            type = with types; ints.between 1 65536;
          };
        };
      };
    };

    whispercpp = mkOption {
      default = {
        port = 8882;
      };

      type = types.submodule {
        options = {
          port = mkOption {
            type = with types; ints.between 1 65536;
          };
        };
      };
    };

    audioCpp = mkOption {
      type = types.submodule {
        options = {
          port = mkOption {
            default = 8881;
            type = with types; ints.between 1 65536;
          };

          models = mkOption {
            default = [];
            type = types.listOf types.attrs;
          };

          config = mkOption {
            readOnly = true;
            default = {
              lazy_load = true;
              log_request_body = false;
              max_request_body_bytes = 2147483648;

              models = cfg.audioCpp.models;
            };
            type = types.attrs;
          };

          configJSON = mkOption {
            readOnly = true;
            type = types.package;
            default = jsonFormat.generate "config.json" cfg.audioCpp.config;
          };
        };
      };
    };

    litellmYaml = mkOption {
      readOnly = true;
      type = types.package;
      default = yamlFormat.generate "config.yaml" config.services.litellm.settings;
    };
  };


  config = lib.mkIf cfg.enable {
    services.postgresql.ensureDatabases = [ "open-webui" ];
    services.postgresql.ensureUsers = [
      { name = "open-webui"; ensureDBOwnership = true; }
    ];

    services.litellm = {
      enable = true;

      environmentFile = cfg.litellmEnvironmentFile;

      settings.model_list = (lib.optionals cfg.enableOpenAIModels (map makeOpenAIModel [
        "gpt-6-astra"
        "gpt-6.1-sol"
        "gpt-6.1-terra"
        "gpt-6-luna"
      ])) ++ (lib.optionals cfg.enableAnthropicModels (map makeAnthropicModel [
        ##
        # Thinking is a request parameter, not a deployment: `thinking` pinned in
        # litellm_params is only a default the client overrides, so a "-thinking"
        # twin buys a second entry per model and nothing else.
        ##
        "claude-haiku-5-5"
        "claude-sonnet-5-5"
        "claude-opus-5-5"
        "claude-opus-4-8"
      ])) ++ (lib.optionals cfg.enableXAIModels [
        ##
        # grok-4-1-fast-* is gone: xAI's documentation no longer lists it, and
        # the cost map has no entry for it, so nothing describes or prices it.
        # These are the current models in its place, both already in the map.
        ##
        {
          model_name = "grok-4.7";
          litellm_params = {
            model = "xai/grok-4.7";
            api_key = "os.environ/XAI_API_KEY";
            additional_drop_params = dropForeignParams;
          };
        }
        {
          model_name = "grok-4.3";
          litellm_params = {
            model = "xai/grok-4.3";
            api_key = "os.environ/XAI_API_KEY";
            additional_drop_params = dropForeignParams;
          };
        }
        {
          model_name = "grok-4.20-non-reasoning";
          litellm_params = {
            model = "xai/grok-4.20-0309-non-reasoning";
            api_key = "os.environ/XAI_API_KEY";
            additional_drop_params = dropForeignParams;
          };
        }
        {
          model_name = "grok-imagine-image";
          litellm_params = {
            model = "xai/grok-imagine-image";
            api_key = "os.environ/XAI_API_KEY";
            additional_drop_params = dropForeignParams ++ [
              "size"
            ];
          };
        }
      ]) ++ (lib.optionals cfg.enableDeepSeekModels [
        {
          model_name = "deepseek-flash";
          litellm_params = {
            model = "deepseek/deepseek-flash";
            api_key = "os.environ/DEEPSEEK_API_KEY";
          };
        }
      ]) ++ [
        {
          model_name = "fireworks-deepseek-v4p1-flash";
          litellm_params = {
            model = "fireworks_ai/accounts/fireworks/models/deepseek-v4p1-flash-1017";
            api_key = "os.environ/FIREWORKS_AI_API_KEY";
            additional_drop_params = dropForeignParams;
          };
        }
        {
          model_name = "kokoro-82m";
          litellm_params = {
            model = "openai/kokoro";
            api_base = "http://localhost:${toString cfg.kokoroTTS.port}/v1";
            api_key = "unnecessary";
          };
          # A local server has no cost-map entry, and without a mode the proxy
          # advertises it as untyped, which offers it to clients as a chat model.
          model_info.mode = "audio_speech";
        }
        {
          model_name = "whisper-1";
          litellm_params = {
            model = "openai/whisper-1";
            api_base = "http://localhost:${toString cfg.whispercpp.port}";
            api_key = "unnecessary";
          };
        }
      ] ++ cfg.litellmExtraModels;
    };

    systemd.services.litellm = {
      confinement.enable = true;
      confinement.mode = "full-apivfs";
      confinement.configureNetworking = true;
      confinement.packages = [
        config.services.litellm.package
        config.services.litellm.environmentFile
      ];

      environment.HOME = config.services.litellm.stateDir;

      ##
      # They've added "litellm/ui" and "litellm/tiktoken-cache" in nixpkgs
      # which severly fucks with impermanence. Undo this.
      ##
      serviceConfig.StateDirectory = lib.mkForce [
        "litellm"
      ];
    };

    services.open-webui = {
      enable = true;
      host = "127.0.0.1";
      port = 8090;

      package = pkgs.open-webui.overrideAttrs(old: {
        propagatedBuildInputs = old.propagatedBuildInputs ++ (with pkgs.python3Packages; [
          psycopg2 itsdangerous aiohttp fastapi pydantic
        ]);
      });

      environmentFile = cfg.openWebUIEnvironmentFile;

      environment = {
        ANONYMIZED_TELEMETRY = "False";
        DO_NOT_TRACK = "True";
        SCARF_NO_ANALYTICS = "True";
        WEBUI_URL = "https://${cfg.hostName}";
        ENABLE_REALTIME_CHAT_SAVE = "True";
        ENABLE_VERSION_UPDATE_CHECK = "False";

        DATABASE_TYPE = "postgresql";
        DATABASE_USER = "open-webui";
        DATABASE_NAME = "open-webui";
        DATABASE_HOST = "127.0.0.1";
        DATABASE_PORT = "${toString config.services.postgresql.settings.port}";

        ENABLE_LOGIN_FORM = "False";
        ENABLE_OAUTH_SIGNUP = "True";
        ENABLE_OAUTH_PERSISTENT_CONFIG = "False";
        OAUTH_MERGE_ACCOUNTS_BY_EMAIL = "True";
        OAUTH_UPDATE_PICTURE_ON_LOGIN = "True";
        ENABLE_OAUTH_ID_TOKEN_COOKIE = "False";

        ENABLE_OAUTH_ROLE_MANAGEMENT = "True";
        OAUTH_ALLOWED_ROLES = "Open WebUI Users,Open WebUI Admins";
        OAUTH_ADMIN_ROLES = "Open WebUI Admins";
        OAUTH_ROLES_CLAIM = "groups";
        OAUTH_CODE_CHALLENGE_METHOD = "S256";

        OAUTH_CLIENT_ID = cfg.oauthClientId;
        OPENID_PROVIDER_URL = cfg.oauthProviderUrl;
        OAUTH_PROVIDER_NAME = cfg.oauthProviderName;
        OAUTH_SCOPES = "openid email profile groups";
        OPENID_REDIRECT_URI = "https://${cfg.hostName}/oauth/oidc/callback";
      };
    };

    virtualisation.oci-containers.containers.kokoro = let
      imageFile = pkgs.dockerTools.pullImage {
        # imageName = "ghcr.io/remsky/kokoro-fastapi-cpu";
        imageName = "git.vs49688.net/oci/kokoro-fastapi-cpu";
        imageDigest = "sha256:adb6694cbdaaa8d2c206c06c4b21eb8dc7f5cda051202ee322d2b66b4f2f787b";
        hash = "sha256-L3qCwC0gaOrP5Nq/Y8IMXmmwYllv3woOu+6i4SD0nhA=";
        finalImageName = "localhost/kokoro-fastapi-cpu";
        finalImageTag = "v0.9.2";
      };
    in {
      inherit imageFile;

      image = "${imageFile.imageName}:${imageFile.imageTag}";

      # Grrr, this breaks ports = []. FIXME: figure out an easy way to do this.
      # extraOptions = [
      #   # Network is unnecessary.
      #   "--network=none"
      # ];

      ports = [
        "127.0.0.1:${toString cfg.kokoroTTS.port}:8880"
      ];

      environment = {
        DOWNLOAD_MODEL = "false";
      };
    };

    systemd.services.whisper-cpp = let
      # whisperModel = pkgs.fetchurl {
      #   url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin";
      #   hash = "sha256-YO1bw90U7qhWST0zQ0m0BXgt3K8AKNS130CINF+6Lv4=";
      # };

      whisperModel = pkgs.fetchurl {
        url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.bin";
        hash = "sha256-G+OpsgY4Z7k35k4ux0gzZKeZF+FX+pjF2UtcH//qmHs=";
      };
    in {
      description = "whisper.cpp STT server";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      # confinement.enable = true; # Fucks with DeviceAllow=

      path = with pkgs; [
        ffmpeg-headless
        whisper-cpp-vulkan
      ];

      serviceConfig = {
        ExecStart = let
          args = [
            "--host" "127.0.0.1"
            "--port" (toString cfg.whispercpp.port)
            "--inference-path" "/audio/transcriptions"
            "-m" whisperModel
            "--convert"
            "--tmp-dir" "/tmp" # PrivateTmp=yes
            "--suppress-nst"
          ];
        in "${pkgs.whisper-cpp-vulkan}/bin/whisper-server ${utils.escapeSystemdExecArgs args}";

        # Identity
        DynamicUser = true;

        # Privilege hardening
        NoNewPrivileges = true;
        PrivateTmp = true;
        PrivateUsers = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectKernelLogs = true;
        ProtectControlGroups = true;
        ProtectClock = true;
        ProtectHostname = true;
        ProtectProc = "invisible";
        ProcSubset = "pid";
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        LockPersonality = true;
        MemoryDenyWriteExecute = false; # Vulkan shader JIT
        RemoveIPC = true;

        # Filesystem
        PrivateDevices = false;
        DeviceAllow = [
          "/dev/dri/card0 rw"
          "/dev/dri/renderD128 rw"
        ];

        # Network
        RestrictAddressFamilies = [ "AF_INET" "AF_UNIX" ];

        # Syscalls
        SystemCallArchitectures = "native";
        SystemCallFilter = [
          "@system-service"
          "@pkey"
          "~@privileged"
          "~@obsolete"
        ];

        CapabilityBoundingSet = "";
        AmbientCapabilities = "";
      };
    };

    systemd.services.audio-cpp = {
      description = "audio.cpp TTS server";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      # confinement.enable = true; # Fucks with DeviceAllow=

      path = with pkgs; [
        audio-cpp
      ];

      serviceConfig = {
        ExecStart = let
          args = [
            "--host"      "127.0.0.1"
            "--port"      (toString cfg.audioCpp.port)
            "--ui"
            "--backend"   "vulkan"
            "--config"    (toString cfg.audioCpp.configJSON)
            "--voice-dir" "/var/lib/audiocpp/voices"
          ];
        in [
          "${pkgs.audio-cpp}/bin/audiocpp_server ${utils.escapeSystemdExecArgs args}"
        ];

        StateDirectory = [
          "audiocpp"
        ];

        # Identity
        DynamicUser = true;

        # Privilege hardening
        NoNewPrivileges = true;
        PrivateTmp = true;
        PrivateUsers = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectKernelLogs = true;
        ProtectControlGroups = true;
        ProtectClock = true;
        ProtectHostname = true;
        ProtectProc = "invisible";
        ProcSubset = "pid";
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        LockPersonality = true;
        MemoryDenyWriteExecute = false; # Vulkan shader JIT
        RemoveIPC = true;

        # Filesystem
        PrivateDevices = false;
        DeviceAllow = [
          "/dev/dri/card0 rw"
          "/dev/dri/renderD128 rw"
        ];

        # Network
        RestrictAddressFamilies = [ "AF_INET" "AF_UNIX" ];

        # Syscalls
        SystemCallArchitectures = "native";
        SystemCallFilter = [
          "@system-service"
          "@pkey"
          "~@privileged"
          "~@obsolete"
        ];

        CapabilityBoundingSet = "";
        AmbientCapabilities = "";
      };
    };

    services.caddy.virtualHosts."${cfg.hostName}".extraConfig = ''
      encode zstd gzip
      reverse_proxy http://${config.services.open-webui.host}:${toString config.services.open-webui.port}
    '';
  };
}
