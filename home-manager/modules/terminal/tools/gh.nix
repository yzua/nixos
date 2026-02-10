# GitHub CLI with declarative settings.
{
  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";
      prompt = "enabled";
    };
    gitCredentialHelper.enable = true;
  };
}
