{ lib, pkgs, config, ... }: let
  cfg = config.programs.pi-coding-agent;

  jsonFormat = pkgs.formats.json { };

  myPy = pkgs.python3.withPackages(p: with p; [
    virtualenv

    ddgs
    mcp     # Need for "ddgs mcp"
    fastapi # Also needed for "ddgs mcp"
  ]);
in
{
  options.programs.pi-coding-agent.mcpServers = with lib; mkOption {
    type = types.attrsOf types.attrs;
  };

  config = {
    programs.pi-coding-agent = {
      enable = lib.mkDefault true;
      extraPackages = with pkgs; [
        bun
        nodejs
        gopls
        clang-tools # For clangd
        typescript-language-server
        lldb_22
        myPy
        poppler-utils # For pdftotext
        tinyxxd # LLMs seem to really like xxd
        firefox-devtools-mcp
      ];

      context = builtins.readFile ./AGENTS.md;

      settings = {
        theme = "dark";
        defaultProvider = "deepseek";
        defaultModel = "deepseek-v4-flash";
        packages = [
          "npm:pi-subagents"
          "npm:pi-mcp-adapter"
          "git:github.com/samfoy/pi-lsp-extension@f2433d19c3bb1300dfdc5f4505b062f9c9c0a1a6"
        ];

        enableInstallTelemetry = false;
        defaultThinkingLevel = "max";
        hideThinkingBlock = false;
        npmCommand = [
          "${lib.getExe pkgs.bun}"
        ];
      };

      models = let
        mkDeepseekModel = id: {
          inherit id;

          contextWindow = 1000000;
          maxTokens = 384000;
          reasoning = true;
          input = ["text"];
          api = "openai-completions";
          reasoningEffortMap = {
            minimal = "high";
            low = "high";
            medium = "high";
            high = "high";
            xhigh = "max";
          };
          compat = {
            requiresReasoningContentOnAssistantMessages = true;
            thinkingFormat = "deepseek";
          };
        };
      in {
        providers.litellm = {
          baseUrl = "http://localhost:8080/v1"; # ssh -L8080:localhost:8080
          api = "openai-responses";
          apiKey = "unnecessary";
          models = [
            (mkDeepseekModel "deepseek-v4-pro")
            (mkDeepseekModel "deepseek-v4-flash")
          ];
        };

        providers.deepseek = {
          baseUrl = "https://api.deepseek.com";
          api = "openai-completions";
          # apiKey = ""; # Filled in private config.
          models = [
            (mkDeepseekModel "deepseek-v4-pro")
            (mkDeepseekModel "deepseek-v4-flash")
          ];
        };
      };

      mcpServers = {
        lldb = {
          command = "nc";
          args = [ "localhost" "59999" ]; # FIXME: until lldb-mcp isn't shit
          lifecycle = "lazy";
        };

        ddgs = {
          command = "${myPy}/bin/ddgs";
          args = ["mcp"];
          lifecycle = "lazy";
          directTools = true;
        };

        firefox = {
          command = lib.getExe pkgs.firefox-devtools-mcp;
          args = [
            "--firefox-path" "${lib.getExe pkgs.firefox}"
          ];
          lifecycle = "lazy-keep-alive";
        };
      };
    };

    home.file.".pi/agent/mcp.json".source = jsonFormat.generate "mcp.json" {
      mcpServers = cfg.mcpServers;
    };

    home.file.".pi/agent/extensions/web-request".source = ./web-request;

    home.file.".pi/agent/skills/pdf-to-text".source = ./pdf-to-text;
    home.file.".pi/agent/skills/forgejo-api".source = ./forgejo-api;
  };
}
