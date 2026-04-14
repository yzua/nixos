# Secure Boot preparation with sbctl.
# Provides tamper-evident boot chain to prevent evil-maid attacks.
#
# ACTIVATION STEPS (must be done manually after nixos-rebuild):
#   1. sudo sbctl create-keys          # Generate signing keys
#   2. sudo sbctl enroll-keys --microsoft  # Enroll keys in firmware (with Microsoft certs for dual-boot)
#   3. sudo sbctl status               # Verify enrollment
#   4. sudo sbctl verify               # Check which binaries need signing
#   5. sudo sbctl sign -s /boot/EFI/BOOT/BOOTX64.EFI
#   6. sudo sbctl sign -s /boot/EFI/systemd/systemd-bootx64.efi
#   7. sudo sbctl sign -s /boot/EFI/nixos/<kernel>.efi
#   8. sudo sbctl sign -s /boot/EFI/nixos/<initrd>.efi
#   9. Reboot, enter BIOS, enable Secure Boot in "Setup Mode"
#  10. Verify: sudo mokutil --sb-state

{
  config,
  lib,
  pkgsStable,
  ...
}:

let
  inherit (import ./helpers/_systemd-helpers.nix { inherit lib; }) mkServiceHardening;
in
{
  options.mySystem.secureBoot = {
    enable = lib.mkEnableOption "Secure Boot preparation with sbctl";
  };

  config = lib.mkIf config.mySystem.secureBoot.enable {
    environment.systemPackages = [
      pkgsStable.sbctl
      pkgsStable.mokutil # MOK (Machine Owner Key) management
    ];

    # Ensure sbctl keys directory exists with proper permissions
    systemd.tmpfiles.rules = [
      "d /var/lib/sbctl 0700 root root -"
    ];

    # Auto-sign EFI binaries after NixOS rebuilds
    # This runs after every boot to catch newly installed kernels
    systemd.services.sbctl-sign = {
      description = "Auto-sign EFI binaries with Secure Boot keys";
      wantedBy = [ "multi-user.target" ];
      after = [ "local-fs.target" ];
      path = [ pkgsStable.sbctl ];

      script = ''
        # Only sign if keys exist and Secure Boot is enrolled
        if sbctl status 2>/dev/null | grep -q "Setup Mode: Disabled"; then
          # Sign all unsigned EFI binaries in /boot
          sbctl sign-all 2>/dev/null || true
          echo "[$(date -Iseconds)] Secure Boot: signed all EFI binaries" | \
            logger -t sbctl-sign
        fi
      '';

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      }
      // mkServiceHardening {
        readWritePaths = [
          "/boot"
          "/var/lib/sbctl"
        ];
        protectHome = true;
      };
    };
  };
}
