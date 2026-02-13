# Mise polyglot runtime manager.

{ config, ... }:

{
  programs.mise = {
    enable = true;
    globalConfig.settings = {
      experimental = true;
      verbose = false;
      quiet = false;
      python_compile = false;
      python_venv_auto_create = false;
      disable_tools = [ "python" ];
    };
  };

  home.sessionVariables = {
    MISE_EXPERIMENTAL = "1";
    MISE_PYTHON_COMPILE = "0";
    MISE_PYTHON_VENV_AUTO_CREATE = "0";
    MISE_TELEMETRY = "0";
  };

  home.sessionPath = [ "${config.home.homeDirectory}/.local/share/mise/shims" ];
}
