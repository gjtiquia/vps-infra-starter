#!/usr/bin/env bash

# TODO : (in this order)
# - adduser (input username and pw)
# - user ssh access copy the authorized keys (so no password prompt)
# - ghostty setup for the user
# - setup ~/infra with vps-infra-starter, but rm -rf .git
# - disable password auth, root login, PAM
# - the rest should be sudo on VPS, idempotent there, interactive input sudo pw

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
# set -eux
set -eu

echo "=== gjtiquia/bootstrap-vps: running ==="
echo " "

echo "this is meant to be run in your local machine, make sure you have ssh access to your vps"
echo " "

echo "assumptions:"
echo "- debian 13"
echo "- root user"
echo " "

echo "=== required params: ==="
echo " "

# r = [r]aw - prevents backslash to be treated as escape char
# p = ask with a [p]rompt
# s = [s]ecret input
# e = Readline [e]ditable
# i = prefills [i]nput
# read -p "prompt: " -r var_name
# read -p "secret: " -rs var_name
# read -p "ssh port: " -rei "22" ssh_port

# we assume root anyways, any other value would likely break the script
# read -p "ssh_user: " -rei "root" ssh_user
ssh_user=root

read -p "ssh_ip: " -r ssh_ip
read -p "sudo_user_name: " -r sudo_user_name
read -p "sudo_user_password: " -rs sudo_user_password
echo " "

# we first ensure we no need to enter password for the operations later
echo "=== running ssh-copy-id ==="
echo " "
echo "you may be prompted to enter your password"
echo " "

# tested - idempotent
ssh-copy-id "$ssh_user@$ssh_ip"

# we complete as many things as we can as root so we dont need to run "sudo"

# << = heredoc, use quotes for $ to be resolved on VPS, no quotes for $ to be resolved on local shell
# tested - idempotent
ssh "$ssh_user@$ssh_ip" << 'REMOTE' 

echo "=== installing packages ==="
echo " "

apt update
apt install locales ufw git vim tmux

echo " "

echo "=== setting up firewall ==="
echo " "

ufw status

# proper defaults
ufw default deny incoming
ufw default allow outgoing

# remember to allow ssh access!
ufw allow OpenSSH

# remember to allow HTTP and HTTPS!
ufw allow 80
ufw allow 443

# double check if configuration is correct
ufw show added

# enable
ufw --force enable # force so it doesnt require interactive prompt to confirm
ufw status # shows OpenSSH port 22
ufw status verbose # shows default too


echo "=== setting up sudo user account ==="
echo " "




REMOTE
echo " "


