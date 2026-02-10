# Custom utility scripts added to system PATH.
{ pkgs, user, ... }:

{
  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "ai-ask" ''
      exec /home/${user}/System/scripts/ai/ask.sh "$@"
    '')
    (writeShellScriptBin "ai-help" ''
      exec /home/${user}/System/scripts/ai/help.sh "$@"
    '')
    (writeShellScriptBin "ai-commit" ''
      exec /home/${user}/System/scripts/ai/commit.sh "$@"
    '')
    (writeShellScriptBin "nvidia-fans" ''
      exec /home/${user}/System/scripts/nvidia-fans.sh "$@"
    '')
  ];

  systemd.tmpfiles.rules = [ "d /home/${user}/.local/bin 0755 ${user} users -" ];
}
