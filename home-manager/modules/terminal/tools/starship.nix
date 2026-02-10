# Starship cross-shell prompt with Gruvbox theming.

{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      format = "$directory$git_branch$git_status$nix_shell$python$nodejs$golang$rust$docker_context$cmd_duration$line_break$character";
      add_newline = false;

      character = {
        success_symbol = "[λ](bold green)";
        error_symbol = "[λ](bold red)";
        vimcmd_symbol = "[](bold green)";
      };

      directory = {
        style = "bold blue";
        truncation_length = 3;
        truncate_to_repo = true;
        fish_style_pwd_dir_length = 1;
      };

      git_branch = {
        symbol = " ";
        style = "bold cyan";
        format = "[$symbol$branch]($style) ";
      };

      git_status = {
        style = "bold yellow";
        format = "[$all_status$ahead_behind]($style) ";
        conflicted = "=";
        ahead = "⇡\${count}";
        behind = "⇣\${count}";
        diverged = "⇕⇡\${ahead_count}⇣\${behind_count}";
        untracked = "?";
        stashed = "$";
        modified = "!";
        staged = "+";
        renamed = "»";
        deleted = "✘";
      };

      nix_shell = {
        symbol = " ";
        style = "bold blue";
        format = "[$symbol$state]($style) ";
        heuristic = true;
      };

      python = {
        symbol = " ";
        style = "bold yellow";
        format = "[$symbol$version]($style) ";
      };

      nodejs = {
        symbol = " ";
        style = "bold green";
        format = "[$symbol$version]($style) ";
      };

      golang = {
        symbol = " ";
        style = "bold cyan";
        format = "[$symbol$version]($style) ";
      };

      rust = {
        symbol = " ";
        style = "bold red";
        format = "[$symbol$version]($style) ";
      };

      docker_context = {
        symbol = " ";
        style = "bold blue";
        format = "[$symbol$context]($style) ";
        only_with_files = true;
      };

      cmd_duration = {
        min_time = 2000;
        style = "bold yellow";
        format = "[$duration]($style) ";
      };

      aws.disabled = true;
      gcloud.disabled = true;
      azure.disabled = true;
      package.disabled = true;
    };
  };
}
