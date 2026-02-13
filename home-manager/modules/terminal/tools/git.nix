# Git version control configuration.

{ constants, ... }:

{
  programs = {
    difftastic = {
      enable = true;
      git.enable = true;
    };

    git = {
      enable = true;

      settings = {
        user = {
          inherit (constants.user) name email;
          signingkey = constants.user.signingKey;
        };

        commit.gpgsign = true;
        tag.gpgsign = true;

        alias = {
          st = "status";
          co = "checkout";
          br = "branch";
          lg = "log --oneline --graph --decorate";
          lga = "log --oneline --graph --decorate --all";
          ad = "add";
          cm = "commit -m";
          amend = "commit --amend --no-edit";
          pl = "pull";
          ps = "push";
          df = "diff";
          dft = "diff --cached";
          rs = "restore";
          rst = "restore --staged";
          rb = "rebase";
          rbi = "rebase -i";
          rset = "reset";
          tg = "tag";
          tga = "tag -a";
          cl = "clean -fdi";
          sm = "submodule";
          smu = "submodule update --init --recursive";
          rmt = "remote";
          rmtv = "remote -v";
          cp = "cherry-pick";
          stsh = "stash";
          stshl = "stash list";
          stsha = "stash apply";
          stshd = "stash drop";
          cfg = "config --list";
          cfgg = "config --global --list";
          ign = "!git check-ignore -v";
          recent = "branch --sort=-committerdate --format='%(committerdate:relative)\t%(refname:short)'";
          undo = "reset --soft HEAD~1";
          wip = "!git add -A && git commit -m 'wip: work in progress [skip ci]'";
          aliases = "!git config --get-regexp alias | sort";
        };
      };

      includes = [
        {
          condition = "hasconfig:remote.*.url:https://github.com/**";
          contents.user.email = constants.user.githubEmail;
        }
        {
          condition = "hasconfig:remote.*.url:git@github.com:*/**";
          contents.user.email = constants.user.githubEmail;
        }
      ];

      ignores = [
        ".cache/"
        ".DS_Store"
        ".idea/"
        "*.swp"
        "*.elc"
        "auto-save-list"
        ".direnv/"
        "node_modules"
        "result"
        "result-*"
      ];
    };
  };
}
