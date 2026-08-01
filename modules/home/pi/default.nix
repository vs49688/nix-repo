{ lib, pkgs, ... }: let
  jsonFormat = pkgs.formats.json { };

  myPy = pkgs.python3.withPackages(p: with p; [
    virtualenv

    ddgs
    mcp     # Need for "ddgs mcp"
    fastapi # Also needed for "ddgs mcp"
  ]);
in
{
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
    ];

    context = builtins.readFile ./AGENTS.md;

    settings = {
      theme = "dark";
      defaultProvider = "litellm";
      defaultModel = "deepseek-v4-pro";
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

    models = {
      providers.litellm = {
        baseUrl = "http://localhost:8080/v1"; # ssh -L8080:localhost:8080
        api = "openai-responses";
        apiKey = "unnecessary";
        models = [
          {
            id = "deepseek-v4-pro";
            contextWindow = 1000000;
            reasoning = true;
            thinkingLevelMap = {
              minimal = null;
              low = null;
              medium = null;
              high =  "high";
              xhigh = "high";
              max = "max";
            };
          }
        ];
      };
    };
  };

  home.file.".pi/agent/mcp.json".source = jsonFormat.generate "mcp.json" {
    mcpServers = {
      "lldb" = {
        command = "nc";
        args = [ "localhost" "59999" ]; # FIXME: until lldb-mcp isn't shit
        lifecycle = "lazy";
      };

      "ddgs" = {
        command = "${myPy}/bin/ddgs";
        args = ["mcp"];
        lifecycle = "lazy";
      };
    };
  };

  home.file.".pi/agent/extensions/web-request".source = ./web-request;

  home.file.".pi/agent/skills/pdf-to-text".source = ./pdf-to-text;
  home.file.".pi/agent/skills/forgejo-api".source = ./forgejo-api;
}
