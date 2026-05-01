# Android RE agent-specific MCP servers.
# These are only loaded into the android-re agent's runtime config,
# not shared with other agents (build, plan, review, etc.).

{ pkgs, ... }:

let
  # jpype (used by pyghidra) needs libstdc++.so.6 at runtime.
  # On NixOS the FHS path is not available to uvx, so we inject
  # LD_LIBRARY_PATH from the system gcc lib output.
  gccLib = pkgs.stdenv.cc.cc.lib;
in
{
  programs.aiAgents = {
    androidReMcpServers = {
      pyghidra-mcp = {
        enable = true;
        command = "uvx";
        args = [ "pyghidra-mcp" ];
        env = {
          GHIDRA_INSTALL_DIR = "${pkgs.ghidra-bin}/lib/ghidra";
          LD_LIBRARY_PATH = "${gccLib}/lib";
        };
      };

      apktool-mcp-server = {
        enable = true;
        command = "uvx";
        args = [ "apktool-mcp" ];
      };
    };
  };
}
