# Chrome DevTools MCP CLI wrapper.
# Not available as a plain package — uses writeShellApplication.

{ pkgs, ... }:

{
  home.packages = [
    (pkgs.writeShellApplication {
      name = "chrome-devtools";
      runtimeInputs = [
        pkgs.nodejs
        pkgs.google-chrome
      ];
      text = ''
        npx -y chrome-devtools-mcp@latest --executablePath ${pkgs.google-chrome}/bin/google-chrome-stable "$@"
      '';
    })
  ];
}
