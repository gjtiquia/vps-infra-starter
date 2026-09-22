#!/usr/bin/env sh

# TODO : this would probably be easier as a bootstrap script on VPS with sudo
# - user setup 
#   - .inputrc = set editing-mode vi
#   - tmux setup

# TODO : stretch goals - dev env (nvm, go)
# TODO : stretch goals - shell DX (fzf, zoxide, yazi)
# TODO : stretch goals - neovim deps

# e = [e]xit if a command exits with non-zero status
# u = exit if have [u]nbound variables, prevents typos
# x = print each command and args before e[x]ecution
set -eux

# checks if git is authenticated
# authenticated or note returns exit code 1
# || true lets it run regardless if authenticated or not
ssh -T git@github.com || true

# TODO : 
# - add set editing-mode vi to .inputrc
# - should be idempotent
# - should log when it starts, when it success, or when it already exists

# TODO :
# - clone github.com/gjtiquia/.tmux to ~/.tmux
# - ln -s ~/.tmux/tmux.conf ~/.tmux.conf
# - should be idempotent
# - should log when it starts, when it success, or when it already exists

