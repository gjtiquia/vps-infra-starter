#!/usr/bin/env bash

# e = [e]xit if a command exits with non-zero status
# u = exit if have [u]nbound variables, prevents typos
# x = print each command and args before e[x]ecution
set -eux

# checks if git is authenticated
# authenticated or note returns exit code 1
# || true lets it run regardless if authenticated or not
ssh -T git@github.com || true

# write your automation here
echo "hello world"
