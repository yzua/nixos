# Productivity tools for time tracking and focus management.
{ pkgsStable, ... }:

{
  home.packages = with pkgsStable; [
    porsmo # CLI Pomodoro timer
    watson # Project-based time tracking
    timewarrior # Taskwarrior companion
  ];
}
