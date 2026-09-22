#!/usr/bin/env bash

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

echo "=== configuring readline ==="

inputrc="$HOME/.inputrc"

if [[ -d "$inputrc" ]]; then
  echo "cannot configure readline: $inputrc is a directory" >&2
  exit 1
fi

if [[ -f "$inputrc" ]] && grep -Fqx 'set editing-mode vi' "$inputrc"; then
  echo "skipped: readline vi editing mode is already configured"
else
  # Avoid joining the setting to an existing final line that has no newline.
  if [[ -s "$inputrc" ]] && [[ -n "$(tail -c 1 "$inputrc")" ]]; then
    printf '\n' >> "$inputrc"
  fi
  printf '%s\n' 'set editing-mode vi' >> "$inputrc"
  echo "configured readline vi editing mode"
fi

echo " "
echo "=== configuring tmux ==="

tmux_dir="$HOME/.tmux"
tmux_config="$HOME/.tmux.conf"
tmux_config_source="$tmux_dir/tmux.conf"

if [[ -e "$tmux_dir" ]] || [[ -L "$tmux_dir" ]]; then
  if [[ ! -d "$tmux_dir" ]] || [[ ! -f "$tmux_config_source" ]]; then
    echo "cannot configure tmux: $tmux_dir exists but is not a valid tmux configuration" >&2
    exit 1
  fi
  echo "skipped: tmux configuration repository already exists"
else
  git clone git@github.com:gjtiquia/.tmux.git "$tmux_dir"
  if [[ ! -f "$tmux_config_source" ]]; then
    echo "cannot configure tmux: cloned repository does not contain tmux.conf" >&2
    exit 1
  fi
  echo "cloned tmux configuration repository"
fi

if [[ -L "$tmux_config" ]]; then
  if [[ "$(readlink "$tmux_config")" == "$tmux_config_source" ]]; then
    echo "skipped: tmux configuration symlink already exists"
  else
    echo "cannot configure tmux: $tmux_config points to a different target" >&2
    exit 1
  fi
elif [[ -e "$tmux_config" ]]; then
  echo "cannot configure tmux: $tmux_config already exists and is not a symlink" >&2
  exit 1
else
  ln -s "$tmux_config_source" "$tmux_config"
  echo "created tmux configuration symlink"
fi

# TODO : sudo apt install lazygit

# TODO : .bashrc aliases
# append the following
# # ---
# # custom config
# # ---
# 
# # aliases
# alias q=exit
# alias c=clear
# alias v=vim
# alias lg=lazygit
# alias tn="~/.tmux/tmux-new.sh"
