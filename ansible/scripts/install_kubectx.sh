#!/usr/bin/env bash

set -x

# From https://github.com/ahmetb/kubectx#linux
git clone https://github.com/ahmetb/kubectx.git ~/.kubectx

ln -s ~/.kubectx/kubectx ~/bin/kubectx
ln -s ~/.kubectx/kubens ~/bin/kubens

cat << FOE >> ~/.bashrc


#kubectx and kubens
export PATH=~/.kubectx:\$PATH
FOE

