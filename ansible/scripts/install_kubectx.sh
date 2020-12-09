#!/usr/bin/env bash

set -x

# From https://github.com/ahmetb/kubectx#linux
git clone https://github.com/ahmetb/kubectx.git ~/.kubectx

ln -s ~/.kubectx/kubectx ~/bin/kubectx
ln -s ~/.kubectx/kubens ~/bin/kubens

if [[ "${SHELL}" = "/bin/bash" ]]; then
    export RCFILE="~/.bashrc"
elif [[ "${SHELL}" = "/bin/zsh" ]]; then
    export RCFILE="~/.zshrc"
fi

cat << FOE >> ${RCFILE}


#kubectx and kubens
export PATH=~/.kubectx:\$PATH
FOE
