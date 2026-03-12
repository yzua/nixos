# SSH client hardening (algorithms, forwarding, host key verification).
_:

{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    matchBlocks = {
      "*" = {
        extraOptions = {
          # Prefer modern key exchange and ciphers
          KexAlgorithms = "sntrup761x25519-sha512@openssh.com,curve25519-sha256,curve25519-sha256@libssh.org";
          Ciphers = "chacha20-poly1305@openssh.com,aes256-gcm@openssh.com";
          MACs = "hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com";
          HostKeyAlgorithms = "ssh-ed25519-cert-v01@openssh.com,ssh-ed25519";

          # Security defaults
          ForwardAgent = "no";
          ForwardX11 = "no";
          AddKeysToAgent = "confirm";
          IdentitiesOnly = "yes";
          StrictHostKeyChecking = "ask";
          VerifyHostKeyDNS = "yes";
          UpdateHostKeys = "yes";
          HashKnownHosts = "yes";

          # Connection keepalive
          ServerAliveInterval = "60";
          ServerAliveCountMax = "3";
        };
      };

      "github.com" = {
        hostname = "github.com";
        user = "git";
        extraOptions = {
          PreferredAuthentications = "publickey";
        };
      };

      "codeberg.org" = {
        hostname = "codeberg.org";
        user = "git";
        identityFile = "~/.ssh/id_ed25519";
        extraOptions = {
          AddressFamily = "inet";
          PreferredAuthentications = "publickey";
        };
      };
    };
  };
}
