# Android RE agent-specific MCP servers.
# These are only loaded into the android-re agent's runtime config,
# not shared with other agents (build, plan, review, etc.).

{ pkgs, ... }:

{
  programs.aiAgents = {
    androidReMcpServers = {
      pyghidra-mcp = {
        enable = true;
        command = "uvx";
        args = [ "pyghidra-mcp" ];
        env = {
          GHIDRA_INSTALL_DIR = "${pkgs.ghidra-bin}/lib/ghidra";
        };
      };

      jadx-mcp-server = {
        enable = true;
        command = "uvx";
        args = [
          "--from"
          "git+https://github.com/zinja-coder/jadx-mcp-server"
          "jadx_mcp_server"
        ];
      };

      apktool-mcp-server = {
        enable = true;
        command = "uvx";
        args = [
          "--from"
          "git+https://github.com/zinja-coder/apktool-mcp-server"
          "apktool_mcp_server"
        ];
      };
    };
  };
}
