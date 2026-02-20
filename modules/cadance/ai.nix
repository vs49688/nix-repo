{ lib, config, pkgs, ... }:
let
  cfg = config.cadance.ai;
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

    openWebUIEnvironmentFile = mkOption {
      type = types.str;
    };

    litellmEnvironmentFile = mkOption {
      type = types.str;
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
  };


  config = lib.mkIf cfg.enable {

    services.postgresql.ensureDatabases = [ "open-webui" ];
    services.postgresql.ensureUsers = [
      { name = "open-webui"; ensureDBOwnership = true; }
    ];

    services.litellm = {
      enable = true;

      environmentFile = cfg.litellmEnvironmentFile;

      settings.model_list = (lib.optionals cfg.enableOpenAIModels [
        {
          model_name = "chatgpt-4o-latest";
          litellm_params = {
            model = "openai/responses/chatgpt-4o-latest";
            api_key = "os.environ/OPENAI_API_KEY";
            merge_reasoning_content_in_choices = true;
          };
        }
        {
          model_name = "gpt-4o";
          litellm_params = {
            model = "openai/responses/gpt-4o";
            api_key = "os.environ/OPENAI_API_KEY";
            merge_reasoning_content_in_choices = true;
          };
        }
        {
          model_name = "gpt-5";
          litellm_params = {
            model = "openai/responses/gpt-5";
            api_key = "os.environ/OPENAI_API_KEY";
            merge_reasoning_content_in_choices = true;
          };
        }
        {
          model_name = "gpt-5-chat-latest";
          litellm_params = {
            model = "openai/responses/gpt-5-chat-latest";
            api_key = "os.environ/OPENAI_API_KEY";
            merge_reasoning_content_in_choices = true;
          };
        }
        {
          model_name = "gpt-5-mini";
          litellm_params = {
            model = "openai/responses/gpt-5-mini";
            api_key = "os.environ/OPENAI_API_KEY";
            merge_reasoning_content_in_choices = true;
          };
        }
        {
          model_name = "gpt-5-nano";
          litellm_params = {
            model = "openai/responses/gpt-5-nano";
            api_key = "os.environ/OPENAI_API_KEY";
            merge_reasoning_content_in_choices = true;
          };
        }
        {
          model_name = "dall-e-2";
          litellm_params = {
            model = "openai/dall-e-2";
            api_key = "os.environ/OPENAI_API_KEY";
          };
        }
        {
          model_name = "gpt-4o-mini-tts";
          litellm_params = {
            model = "openai/gpt-4o-mini-tts";
            api_key = "os.environ/OPENAI_API_KEY";
          };
        }
        {
          model_name = "openai-tts-1-hd";
          litellm_params = {
            model = "openai/tts-1-hd";
            api_key = "os.environ/OPENAI_API_KEY";
          };
        }
        {
          model_name = "openai-tts-1";
          litellm_params = {
            model = "openai/tts-1";
            api_key = "os.environ/OPENAI_API_KEY";
          };
        }
        {
          model_name = "dall-e-3";
          litellm_params = {
            model = "openai/dall-e-3";
            api_key = "os.environ/OPENAI_API_KEY";
          };
        }
      ]) ++ (lib.optionals cfg.enableAnthropicModels [
        {
          model_name = "claude-sonnet-4-5-20250929-thinking";
          litellm_params = {
            model = "anthropic/claude-sonnet-4-5-20250929";
            api_key = "os.environ/ANTHROPIC_API_KEY";
            merge_reasoning_content_in_choices = true;
            thinking = {
              type = "enabled";
              budget_tokens = 1024;
            };
          };
        }
        {
          model_name = "claude-sonnet-4-5-20250929";
          litellm_params = {
            model = "anthropic/claude-sonnet-4-5-20250929";
            api_key = "os.environ/ANTHROPIC_API_KEY";
            merge_reasoning_content_in_choices = true;
          };
        }
        {
          model_name = "claude-haiku-4-5-20251001-thinking";
          litellm_params = {
            model = "anthropic/claude-haiku-4-5-20251001";
            api_key = "os.environ/ANTHROPIC_API_KEY";
            merge_reasoning_content_in_choices = true;
            thinking = {
              type = "enabled";
              budget_tokens = 1024;
            };
          };
        }
        {
          model_name = "claude-haiku-4-5-20251001";
          litellm_params = {
            model = "anthropic/claude-haiku-4-5-20251001";
            api_key = "os.environ/ANTHROPIC_API_KEY";
            merge_reasoning_content_in_choices = true;
          };
        }
        {
          model_name = "claude-opus-4-5-20251101-thinking";
          litellm_params = {
            model = "anthropic/claude-opus-4-5-20251101";
            api_key = "os.environ/ANTHROPIC_API_KEY";
            merge_reasoning_content_in_choices = true;
            thinking = {
              type = "enabled";
              budget_tokens = 1024;
            };
          };
        }
        {
          model_name = "claude-opus-4-5-20251101";
          litellm_params = {
            model = "anthropic/claude-opus-4-5-20251101";
            api_key = "os.environ/ANTHROPIC_API_KEY";
            merge_reasoning_content_in_choices = true;
          };
        }
      ]) ++ (lib.optionals cfg.enableXAIModels [
        {
          model_name = "grok-4-1-fast-reasoning";
          litellm_params = {
            model = "xai/grok-4-1-fast-reasoning";
            api_key = "os.environ/XAI_API_KEY";
            merge_reasoning_content_in_choices = true;
          };
        }
        {
          model_name = "grok-4-1-fast-non-reasoning";
          litellm_params = {
            model = "xai/grok-4-1-fast-non-reasoning";
            api_key = "os.environ/XAI_API_KEY";
            merge_reasoning_content_in_choices = true;
          };
        }
        {
          model_name = "grok-2-image";
          litellm_params = {
            model = "xai/grok-2-image";
            api_key = "os.environ/XAI_API_KEY";
            additional_drop_params = [
              "size"
            ];
          };
        }
        {
          model_name = "grok-2-image-1212";
          litellm_params = {
            model = "xai/grok-2-image-1212";
            api_key = "os.environ/XAI_API_KEY";
            additional_drop_params = [
              "size"
            ];
          };
        }
      ]);
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

    services.caddy.virtualHosts."${cfg.hostName}".extraConfig = ''
      encode zstd gzip
      reverse_proxy http://${config.services.open-webui.host}:${toString config.services.open-webui.port}
    '';
  };
}
