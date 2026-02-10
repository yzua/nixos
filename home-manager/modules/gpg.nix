# GnuPG agent and key configuration.

{ pkgsStable, lib, ... }:

{
  programs.gpg = {
    enable = true;

    settings = {
      personal-cipher-preferences = "AES256";
      personal-digest-preferences = "SHA512";
      personal-compress-preferences = "ZLIB BZIP2 ZIP Uncompressed";
      default-preference-list = "SHA512 AES256 ZLIB BZIP2 ZIP Uncompressed";
      cert-digest-algo = "SHA512";
      s2k-digest-algo = "SHA512";
      s2k-cipher-algo = "AES256";
      charset = "utf-8";
      fixed-list-mode = true;
      no-comments = true;
      no-emit-version = true;
      no-greeting = true;
      keyid-format = "0xlong";
      list-options = "show-uid-validity";
      verify-options = "show-uid-validity";
      with-key-origin = true;
      require-cross-certification = true;
      no-symkey-cache = true;
      use-agent = true;
      throw-keyids = true;
    };
  };

  services.gpg-agent = lib.mkIf (!pkgsStable.stdenv.isDarwin) {
    enable = true;
    defaultCacheTtl = 1800;
    maxCacheTtl = 1800;
    enableSshSupport = false; # KeePassXC handles SSH agent
    pinentry.package = pkgsStable.pinentry-gnome3;
  };
}
