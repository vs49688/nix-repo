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

  piCodingAgent = pkgs.callPackage ./pi-coding-agent.nix { };

  piScripts = pkgs.callPackage ./scripts { };
in
{
  options.programs.pi-coding-agent.mcpServers = with lib; mkOption {
    type = types.attrsOf types.attrs;
  };

  options.settings.pi.packages = with lib; mkOption {
    readOnly = true;
    type = types.attrsOf types.package;

    default = {

      cloudflare-security-audit-skill = pkgs.fetchFromGitHub {
        owner = "cloudflare";
        repo = "security-audit-skill";
        rev = "c1c8a8c1471069fb0e188eeaff69b8e8db6564a8";
        hash = "sha256-oVVACjotkHvllQGxEP8yWaEt4c3GxT0d909TUM5P3NM=";
      };

      lsp-extension = pkgs.pi-lsp-extension;

      openai-long-context = pkgs.fetchFromGitHub {
        owner = "johnhenaot";
        repo = "pi-openai-long-context";
        rev = "8c4cccdf296805f12053558d9dd671ad579fc53a";
        hash = "sha256-SbX0mvyyHk5wVDbJnzWBR9tI9iI7R8DNdEhlPBOPvdI=";
      };
    };
  };

  config = {
    programs.pi-coding-agent = {
      enable = lib.mkDefault true;
      package = piCodingAgent;
      extraPackages = with pkgs; [
        bun
        nodejs
        gopls
        clang-tools # For clangd
        typescript-language-server
        lldb_22
        rizin   # REA's rizin_* tools shell out to it
        kuna
        myPy
        poppler-utils # For pdftotext
        tinyxxd # LLMs seem to really like xxd
        firefox-devtools-mcp
        piScripts
      ];

      context = builtins.readFile ./AGENTS.md
        + lib.optionalString pkgs.stdenv.hostPlatform.isLinux (builtins.readFile ./AGENTS-linux.md);

      settings = {
        theme = "dark";
        defaultProvider = "deepseek";
        defaultModel = "deepseek-flash";
        # A GPT parent must not silently make ordinary delegations use GPT too.
        subagents.defaultModel = "deepseek/deepseek-flash";
        extensions = [
          "-builtin:mcp"
        ];
        packages = [
          "npm:pi-subagents@v0.77.0"
          "npm:pi-mcp-adapter@v5.2.0"
          "${config.settings.pi.packages.lsp-extension}"
          "${config.settings.pi.packages.openai-long-context}"
        ];

        enableInstallTelemetry = false;
        defaultThinkingLevel = "max";
        hideThinkingBlock = false;
        npmCommand = [
          "${lib.getExe pkgs.bun}"
        ];

        compaction = {
          enabled = false;
          reserveTokens =  100000;
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

        ddgs = {
          command = "${myPy}/bin/ddgs";
          args = ["mcp"];
          lifecycle = "lazy";
          directTools = [ "search_text" "extract_content" ];
        };

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
            # REA drives kuna as an optional provider, and will not go looking
            # for it: the command has to be an absolute path. It reports any
            # release other than the one it verified as unverified, which is
            # the check passing with a note, not a refusal.
            REA_KUNA_COMMAND = lib.getExe pkgs.kuna;
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
    home.file.".pi/agent/extensions/litellm-models".source = ./litellm-models;

    home.file.".pi/agent/prompts/afk.md".source = ./prompts/afk.md;
    home.file.".pi/agent/prompts/context-low.md".source = ./prompts/context-low.md;
    home.file.".pi/agent/prompts/decommission.md".source = ./prompts/decommission.md;
    home.file.".pi/agent/prompts/recommission.md".source = ./prompts/recommission.md;
    home.file.".pi/agent/prompts/wide.md".source = ./prompts/wide.md;
    home.file.".pi/agent/prompts/mine.md".source = ./prompts/mine.md;

    # One file per mount rather than the directory, so a definition can be
    # dropped in and read without a rebuild; a directory mount would also take
    # over ~/.pi/agent/agents and shadow anything hand-written there.
    home.file.".pi/agent/agents/re-analyst.md".source = ./agents/re-analyst.md;
    home.file.".pi/agent/agents/researcher.md".source = ./agents/researcher.md;
    home.file.".pi/agent/agents/reviewer.md".source = ./agents/reviewer.md;
    home.file.".pi/agent/agents/spec-implementer.md".source = ./agents/spec-implementer.md;
    home.file.".pi/agent/agents/spec-reader.md".source = ./agents/spec-reader.md;
    home.file.".pi/agent/agents/spec-verifier.md".source = ./agents/spec-verifier.md;
    home.file.".pi/agent/agents/transcript-miner.md".source = ./agents/transcript-miner.md;

    # REA's workflow instructions ship inside the package; they are versioned
    # against the same catalog the server advertises.
    home.file.".pi/agent/skills/reverse-engineer-anything".source =
      "${pkgs.rea-agents}/lib/node_modules/rea-agents/skills/reverse-engineer-anything";

    home.file.".pi/agent/skills/pdf-to-text".source = ./pdf-to-text;
    home.file.".pi/agent/skills/forgejo-api".source = ./forgejo-api;
    home.file.".pi/agent/skills/house-conventions".source = ./house-conventions;

    home.file.".pi/agent/skills/security-audit".source = "${config.settings.pi.packages.cloudflare-security-audit-skill}/skills/security-audit";

    # Likewise Kuna's, which is embedded in its binary. `kuna install-skill`
    # would write a copy into $HOME; the package already carries the same bytes,
    # and the skill names itself kuna-decompiler.
    home.file.".pi/agent/skills/kuna-decompiler".source = "${pkgs.kuna}/share/kuna/skill";
  };
}
