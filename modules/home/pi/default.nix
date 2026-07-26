{ lib, pkgs, ... }:
{
  programs.pi-coding-agent = {
    enable = lib.mkDefault true;
    extraPackages = with pkgs; [
      bun
      gopls
      clang-tools # For clangd
      lldb_22
    ];

    context = builtins.readFile ./AGENTS.md;

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
}
