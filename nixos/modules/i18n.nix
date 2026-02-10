# Internationalization, locale, input methods, and keyboard layout.
{
  constants,
  pkgs,
  ...
}:

{
  i18n = {
    defaultLocale = "en_US.UTF-8";

    # PRIVACY: en_US for all categories to blend with largest English-speaking locale pool
    extraLocaleSettings = {
      LC_ADDRESS = "en_US.UTF-8";
      LC_IDENTIFICATION = "en_US.UTF-8";
      LC_MEASUREMENT = "en_US.UTF-8";
      LC_MONETARY = "en_US.UTF-8";
      LC_NAME = "en_US.UTF-8";
      LC_NUMERIC = "en_US.UTF-8";
      LC_PAPER = "en_US.UTF-8";
      LC_TELEPHONE = "en_US.UTF-8";
      LC_TIME = "en_US.UTF-8";
    };

    inputMethod = {
      enable = true;
      type = "fcitx5";

      fcitx5 = {
        waylandFrontend = true;

        addons = with pkgs; [
          fcitx5-gtk
          qt6Packages.fcitx5-configtool
          qt6Packages.fcitx5-chinese-addons
          fcitx5-anthy
        ];
      };
    };
  };

  services.xserver.xkb = {
    inherit (constants.keyboard) layout variant options;
  };

  # NOTE: Using environment.variables (not sessionVariables) because PAM pam_env
  # requires @{var} brace syntax, but @im=fcitx is a literal value.
  environment = {
    variables = {
      QT_IM_MODULE = "fcitx";
      XMODIFIERS = "@im=fcitx";
      SDL_IM_MODULE = "fcitx";
      INPUT_METHOD = "fcitx";
      GLFW_IM_MODULE = "ibus"; # GLFW fallback
    };

    systemPackages = with pkgs; [
      qt6Packages.fcitx5-with-addons
      libpinyin
    ];
  };
}
