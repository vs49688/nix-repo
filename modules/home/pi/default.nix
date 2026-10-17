{ lib, pkgs, config, ... }: let
  cfg = config.programs.pi-coding-agent;

  jsonFormat = pkgs.formats.json { };

  myPy = pkgs.python3.withPackages(p: with p; [
    virtualenv

    ddgs
    mcp     # Need for "ddgs mcp"
    fastapi # Also needed for "ddgs mcp"
  ]);

  ##
  # REA drives Ghidra headlessly over its own loopback bridge. Running it in a
  # network namespace with no external route keeps that working (loopback is
  # brought back up) while nothing it spawns can fetch anything -- including a
  # future `rea update`, which shells out to npm.
  ##
  reaMcp = pkgs.writeShellScript "rea-mcp-offline" ''
    ${lib.getExe' pkgs.iproute2 "ip"} link set lo up
    exec ${lib.getExe pkgs.rea-agents} mcp
  '';
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
        rizin   # REA's rizin_* tools shell out to it
        myPy
        poppler-utils # For pdftotext
        tinyxxd # LLMs seem to really like xxd
        firefox-devtools-mcp
      ];

      context = builtins.readFile ./AGENTS.md;

      settings = {
        theme = "dark";
        tuiMode = "regular";
        fullscreenCopyOnSelect = false;
        defaultProvider = "deepseek";
        defaultModel = "deepseek-flash";
        extensions = [
          "-builtin:mcp"
        ];
        packages = [
          "npm:pi-subagents@v0.77.0"
          "npm:pi-mcp-adapter@v5.2.0"
          "git:github.com/samfoy/pi-lsp-extension@v1.4.0"
        ];

        enableInstallTelemetry = false;
        defaultThinkingLevel = "max";
        hideThinkingBlock = false;
        npmCommand = [
          "${lib.getExe pkgs.bun}"
        ];

        compaction = {
          enabled = false;
          reserveTokens =  64000;
          keepRecentTokens = 300000;
        };
      };

      models = let
        mkDeepseekModel = id: {
          inherit id;

          contextWindow = 1000000;
          maxTokens = 384000;
          reasoning = true;
          input = ["text" "image"];
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
            (mkDeepseekModel "deepseek-flash")
          ];
        };

        providers.deepseek = {
          baseUrl = "https://api.deepseek.com";
          api = "openai-completions";
          # apiKey = ""; # Filled in private config.
          models = [
            (mkDeepseekModel "deepseek-flash")
          ];
        };
      };

      mcpServers = {
        lldb = {
          command = "nc";
          args = [ "localhost" "59999" ]; # FIXME: until lldb-mcp isn't shit
          lifecycle = "lazy";
        };

        # ddgs = {
        #   command = "${myPy}/bin/ddgs";
        #   args = ["mcp"];
        #   lifecycle = "lazy";
        #   directTools = true;
        # };

        firefox = {
          command = lib.getExe pkgs.firefox-devtools-mcp;
          args = [
            "--firefox-path" "${lib.getExe pkgs.firefox}"
          ];
          lifecycle = "lazy-keep-alive";
        };

        rea = {
          command = lib.getExe' pkgs.util-linux "unshare";
          args = [
            # --user --map-root-user --net
            "-r" "--net" "--"
            reaMcp
          ];
          env = {
            GHIDRA_INSTALL_DIR = "${pkgs.ghidra}/lib/ghidra";
            JAVA_HOME = "${pkgs.jdk21}/lib/openjdk";
          };
          lifecycle = "lazy";
        };
      };
    };

    home.file.".pi/agent/mcp-adapter.json".force = true;
    home.file.".pi/agent/mcp-adapter.json".source = jsonFormat.generate "mcp-adapter.json" {
      mcpServers = cfg.mcpServers;
    };

    home.file.".pi/agent/extensions/web-request".source = ./web-request;
    home.file.".pi/agent/extensions/context-gauge".source = ./context-gauge;

    # REA's workflow instructions ship inside the package; they are versioned
    # against the same catalog the server advertises.
    home.file.".pi/agent/skills/reverse-engineer-anything".source =
      "${pkgs.rea-agents}/lib/node_modules/rea-agents/skills/reverse-engineer-anything";

    home.file.".pi/agent/skills/pdf-to-text".source = ./pdf-to-text;
    home.file.".pi/agent/skills/forgejo-api".source = ./forgejo-api;
    home.file.".pi/agent/skills/house-conventions".source = ./house-conventions;
  };
}
