# Git settings, aliases, conditional includes, and global ignores.

{
  constants,
  ...
}:

let
  githubRemoteIncludeConditions = [
    "hasconfig:remote.*.url:https://github.com/**"
    "hasconfig:remote.*.url:git@github.com:*/**"
  ];
  githubEmailIncludes = map (condition: {
    inherit condition;
    contents.user.email = constants.user.githubEmail;
  }) githubRemoteIncludeConditions;
in

{
  programs = {
    difftastic = {
      enable = true;
      git.enable = true;
    };

    git = {
      enable = true;

      # === Signing (defense layer 1/3: auto-sign every commit and tag) ===
      signing = {
        key = constants.user.signingKey;
        format = "openpgp";
        signByDefault = true; # sets commit.gpgSign + tag.gpgSign = true
      };

      settings = {
        user = {
          inherit (constants.user) name email;
        };

        # === Pull / Push ===
        pull.rebase = true; # clean history by default
        push = {
          autoSetupRemote = true; # no more --set-upstream
          gpgSign = "if-asked"; # sign pushes when server supports it
        };

        # === Merge / Rebase ===
        merge.conflictstyle = "zdiff3"; # better conflict markers with common ancestor
        rerere.enabled = true; # remember conflict resolutions
        rebase = {
          autoStash = true; # auto stash/pop dirty tree on rebase
          autoSquash = true; # auto-apply fixup!/squash! commits
          updateRefs = true; # update stacked branches on rebase
        };

        # === Diff ===
        diff.algorithm = "histogram"; # better diff quality

        # === Fetch ===
        fetch = {
          prune = true; # clean dead remote branches
          pruneTags = true; # clean dead remote tags
          fsckobjects = true; # integrity check on fetch
        };

        # === Transfer integrity ===
        transfer.fsckobjects = true;
        receive.fsckobjects = true;

        # === Interactive rebase ===
        sequence.editor = "interactive-rebase-tool";

        # === UI ===
        column.ui = "auto";
        branch.sort = "-committerdate"; # recent branches first
        tag.sort = "-version:refname"; # newest version tags first
        log.date = "iso";
        status.showUntrackedFiles = "all"; # show individual untracked files

        # === Defaults ===
        init.defaultBranch = "main";
        help.autocorrect = "prompt"; # ask before running corrected command

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
          changelog = "!git-cliff -o CHANGELOG.md"; # generate changelog (requires git-cliff)
        };
      };

      includes = githubEmailIncludes;

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
        ".beads/"
      ];
    };
  };
}
