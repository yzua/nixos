# Zsh local variables: editor, pager, FZF, XDG tool caches, language tool homes.

{
  config,
  constants,
  ...
}:

{
  programs.zsh.localVariables = {
    # FZF commands and previews
    FZF_DEFAULT_COMMAND = "fd --type f --hidden --follow --exclude .git";
    FZF_CTRL_T_COMMAND = "$FZF_DEFAULT_COMMAND";
    FZF_ALT_C_COMMAND = "fd --type d --hidden --follow --exclude .git";
    FZF_CTRL_T_OPTS = "--preview 'bat --color=always --style=numbers --line-range=:500 {}'";
    FZF_ALT_C_OPTS = "--preview 'eza --tree --level=2 --color=always {}'";

    LS_COLORS = "di=1;34:ln=1;36:so=1;35:pi=1;33:ex=1;32:bd=1;33:cd=1;33:su=1;31:sg=1;31:tw=1;34:ow=1;34"; # Fallback if vivid unavailable

    VISUAL = constants.editor;
    PAGER = "bat";
    MANPAGER = "sh -c 'col -bx | bat -l man -p'";

    LESS = "-R";
    LESSHISTFILE = "${config.xdg.cacheHome}/less/history";
    LESSHISTSIZE = "1000";

    # --wait flag blocks until file is closed (required for interactive git operations)
    GIT_EDITOR = "${constants.editor} --wait";
    GIT_PAGER = "bat";

    PIP_CACHE_DIR = "${config.xdg.cacheHome}/pip";
    NODE_REPL_HISTORY = "${config.xdg.dataHome}/node/node_repl_history";
    NPM_CONFIG_CACHE = "${config.xdg.cacheHome}/npm";
    YARN_CACHE_FOLDER = "${config.xdg.cacheHome}/yarn";

    CGO_ENABLED = "1";

    # Tool homes (static values, no need for shell export)
    CARGO_HOME = "$HOME/.cargo";
    RUSTUP_HOME = "$HOME/.rustup";
    PYENV_ROOT = "$HOME/.pyenv";
    NVM_DIR = "$HOME/.nvm";
    COMPOSER_HOME = "$HOME/.config/composer";
  };
}
