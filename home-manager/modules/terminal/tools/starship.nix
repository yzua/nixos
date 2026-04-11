# Starship cross-shell prompt with GruvboxAlt theming.

let
  mkVersionModule = style: {
    symbol = " ";
    inherit style;
    format = "[$symbol$version]($style) ";
  };
in

{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      scan_timeout = 200;
      format = "$directory$git_branch$git_status$nix_shell$cmd_duration$line_break$character";
      add_newline = false;

      character = {
        success_symbol = "[❯](bold green) ";
        error_symbol = "[❯](bold red) ";
        vimcmd_symbol = "[](bold green)";
      };

      directory = {
        style = "bold blue";
        truncation_length = 3;
        truncate_to_repo = true;
        fish_style_pwd_dir_length = 1;
        format = "[󰉋 $path]($style) ";
      };

      git_branch = {
        symbol = " ";
        style = "bold cyan";
        format = "[$symbol$branch]($style)";
      };

      git_status = {
        style = "bold yellow";
        format = " [($all_status$ahead_behind)]($style)";
        conflicted = "=";
        ahead = "⇡\${count}";
        behind = "⇣\${count}";
        diverged = "⇕⇡\${ahead_count}⇣\${behind_count}";
        untracked = "?";
        stashed = "*";
        modified = "~";
        staged = "+";
        renamed = "»";
        deleted = "✘";
      };

      nix_shell = {
        symbol = " ";
        style = "bold blue";
        format = " [($symbol$state)]($style)";
        heuristic = true;
      };

      python = mkVersionModule "bold yellow";

      nodejs = mkVersionModule "bold green";

      golang = mkVersionModule "bold cyan";

      rust = mkVersionModule "bold red";

      docker_context = {
        symbol = " ";
        style = "bold blue";
        format = "[$symbol$context]($style) ";
        only_with_files = true;
      };

      cmd_duration = {
        min_time = 2000;
        style = "bold yellow";
        format = " [󱎫 $duration]($style)";
      };

      aws.disabled = true;
      gcloud.disabled = true;
      azure.disabled = true;
      package.disabled = true;
      username.disabled = true;
      hostname.disabled = true;
    };
  };
}
