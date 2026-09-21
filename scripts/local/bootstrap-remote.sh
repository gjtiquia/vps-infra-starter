#!/usr/bin/env bash

# This is a one-shot bootstrap script. Once it finishes, root SSH login is
# disabled and a later run assumes the VPS was already bootstrapped.

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
echo " "

# we first ensure we no need to enter password for the operations later
echo "=== running ssh-copy-id ==="
echo " "
echo "you may be prompted to enter your password"
echo " "

# tested - idempotent until the final step disables root SSH login
if ! ssh-copy-id "$ssh_user@$ssh_ip"; then
  echo " "
  echo "root SSH access is unavailable."
  echo "assuming this VPS was already bootstrapped; nothing to do."
  exit 0
fi

read -p "sudo_user_name: " -r sudo_user_name
read -p "sudo_user_password: " -rs sudo_user_password
echo " "

if [[ ! "$sudo_user_name" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
  echo "invalid sudo user name" >&2
  exit 1
fi

if [[ -z "$sudo_user_password" ]]; then
  echo "sudo user password cannot be empty" >&2
  exit 1
fi

# we complete as many things as we can as root so we dont need to run "sudo"

# << = heredoc, use quotes for $ to be resolved on VPS, no quotes for $ to be resolved on local shell
# Send the credentials over SSH's stdin instead of putting the password in the
# remote command (where it could be visible in a process listing). The remote
# shell reads the first two lines, then bash reads the script that follows.
{
  printf '%s\n' "$sudo_user_name" "$sudo_user_password"
  cat <<'REMOTE'
echo "=== installing packages ==="
echo " "

apt update
apt install -y locales ufw git vim tmux sudo

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

if ! id -u "$sudo_user_name" >/dev/null 2>&1; then
  adduser --disabled-password --gecos "" "$sudo_user_name"
  echo "created user: $sudo_user_name"
else
  echo "skipped: user $sudo_user_name already exists"
fi

# There is no simple, safe way to compare a plaintext password with its stored
# hash, so reapply it to guarantee the requested password is set.
printf '%s:%s\n' "$sudo_user_name" "$sudo_user_password" | chpasswd
echo "set password for user: $sudo_user_name"

if ! id -nG "$sudo_user_name" | tr ' ' '\n' | grep -qx sudo; then
  usermod -aG sudo "$sudo_user_name"
  echo "granted sudo access to user: $sudo_user_name"
else
  echo "skipped: user $sudo_user_name already has sudo access"
fi

if [[ ! -f /root/.ssh/authorized_keys ]]; then
  echo "cannot copy SSH keys: /root/.ssh/authorized_keys does not exist" >&2
  exit 1
fi

user_ssh_dir="/home/$sudo_user_name/.ssh"
user_authorized_keys="$user_ssh_dir/authorized_keys"

install -d -m 700 -o "$sudo_user_name" -g "$sudo_user_name" "$user_ssh_dir"

if [[ -f "$user_authorized_keys" ]] \
  && cmp -s /root/.ssh/authorized_keys "$user_authorized_keys" \
  && [[ "$(stat -c '%U:%G:%a' "$user_authorized_keys")" == "$sudo_user_name:$sudo_user_name:600" ]]; then
  echo "skipped: authorized keys already copied for user $sudo_user_name"
else
  install -m 600 -o "$sudo_user_name" -g "$sudo_user_name" \
    /root/.ssh/authorized_keys "$user_authorized_keys"
  echo "copied root authorized keys to user: $sudo_user_name"
fi

REMOTE
} | ssh "$ssh_user@$ssh_ip" \
  'IFS= read -r sudo_user_name; IFS= read -r sudo_user_password; export sudo_user_name sudo_user_password; bash -se'
unset sudo_user_password
echo " "

echo "=== setting ghostty ==="
echo " "

infocmp -x xterm-ghostty | ssh "$ssh_user@$ssh_ip" -- tic -x -
echo " "

# Batch mode and disabled password methods prove that key-based login works
# before root access is removed.
ssh -A -o BatchMode=yes -o PasswordAuthentication=no \
  -o KbdInteractiveAuthentication=no "$sudo_user_name@$ssh_ip" <<'REMOTE'

echo " "
echo "=== setting up ~/infra ==="
echo " "

# Agent forwarding provides authentication, but GitHub's host key must still be
# trusted separately on the VPS. A heredoc is non-interactive, so SSH cannot ask
# whether to add an unknown host key.
if ! ssh-add -L >/dev/null 2>&1; then
  echo "no SSH key is available through agent forwarding" >&2
  echo "run 'ssh-add' locally, then rerun this script" >&2
  exit 1
fi

install -d -m 700 "$HOME/.ssh"
if ssh-keygen -F github.com >/dev/null; then
  echo "skipped: GitHub host key already trusted"
else
  ssh-keyscan -H github.com >> "$HOME/.ssh/known_hosts"
  chmod 600 "$HOME/.ssh/known_hosts"
  echo "added GitHub host key to known_hosts"
fi

if [[ -e "$HOME/infra" || -L "$HOME/infra" ]]; then
  echo "skipped: $HOME/infra already exists"
else
  git clone git@github.com:gjtiquia/vps-infra-starter "$HOME/infra"
  echo "cloned repo to: $HOME/infra"

  rm -rf "$HOME/infra/.git"
  echo "removed Git metadata from: $HOME/infra"
fi

REMOTE
echo " "

echo "=== disabling password authentication and root SSH login ==="
echo " "

# Reaching this point proves that a fresh SSH connection as the sudo user works.
# This is intentionally the final operation: future runs will treat unavailable
# root SSH access as evidence that bootstrap already completed.
ssh "$ssh_user@$ssh_ip" <<'REMOTE'

hardening_file=/etc/ssh/sshd_config.d/00-bootstrap-hardening.conf

cat > "$hardening_file" <<'SSHD_CONFIG'
# Managed by bootstrap-remote.sh
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitRootLogin no
SSHD_CONFIG

# Refuse to reload SSH if the resulting configuration is invalid.
sshd -t
systemctl reload ssh

echo "disabled SSH password authentication and root login"

REMOTE

echo " "
echo "=== bootstrap complete ==="
echo "root SSH access is now disabled; this script is not intended to run again."
echo " "
