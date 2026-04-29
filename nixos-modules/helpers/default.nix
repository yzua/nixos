# Shared helpers for NixOS modules.
#
# These are _-prefixed helper files, imported manually by consumers.
# Do NOT add them to imports — modules-check enforces this convention.
#
# Available helpers:
#   _systemd-helpers.nix  — mkServiceHardening, mkPersistentTimer, mkOneshotService
#   _service-urls.nix     — Auto-generated localhost URLs from constants.ports
#
# Usage (from a sibling module):
#   inherit (systemdHelpers) mkPersistentTimer;
#   svcUrls = import ../helpers/_service-urls.nix { inherit constants; };

{ }
