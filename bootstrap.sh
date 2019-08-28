#!/usr/bin/env bash

####################
# VARS             #
####################

RUBY_VERSION="2.5.5"
BUNDLER_VERSION="1.17.3"

NODE_VERSION="8.10.0"
YARN_VERSION="1.15.2"

SSH_KEY="$HOME/.ssh/id_rsa"
SSH_CONFIG="$HOME/.ssh/config"

####################
# Helpers          #
####################

log() {
  # shellcheck disable=SC2155
  local ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  local fmt="$ts\t$1"; shift
  # shellcheck disable=SC2059
  printf "\\n$fmt\\n" "$@"
}

check_installed() {
  if command -v "$1" > /dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

append_to_bash_profile() {
  local text="$1"
  local bash_profile="$HOME/.bash_profile"
  if ! grep -Fqs "$text" "$bash_profile"; then
    log "⚠️  Appending to bash_profile:\n\t%s" "$text"
    printf "\\n%s\\n" "$text" >> "$bash_profile"
  else
    log "✅ bash_profile already has:\n\t%s" "$text"
  fi
}

####################
# Bootstrap Scripts #
####################

install_homebrew() {
  if check_installed brew; then
    log "✅ homebrew is already installed"
  else
    log "⚠️  Installing homebrew"
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    log "✅ homebrew installed"
  fi
}

brew_bundle() {
  log "⚠️  Installing homebrew packages from Brewfile"
  brew update && \
    brew bundle --file=./files/Brewfile
  log "✅ Homebrew packages up to date"
}

launch_docker() {
  log "⚠️  Launching Docker"
  open /Applications/Docker.app
}

install_aws() {
  if check_installed aws; then
    log "✅ awscli is already installed"
  else
    log "⚠️  Installing awscli"
    pip3 install awscli
    log "✅ awscli installed"
  fi
}

install_ruby() {
  log "⚠️  Installing Ruby"

  eval "$(rbenv init -)"

  rbenv install --skip-existing "$RUBY_VERSION"
  rbenv shell "$RUBY_VERSION"
  ruby --version
  gem install bundler -v "$BUNDLER_VERSION"

  # set global default
  rbenv global "$RUBY_VERSION"

  rbenv rehash
  rbenv versions
  log "✅ Ruby installed"
}

install_nodejs() {
  log "⚠️  Installing Nodejs"

  # nvm needs these in bash_profile
  # shellcheck disable=SC2016
  append_to_bash_profile 'export NVM_DIR="$HOME/.nvm"'
  append_to_bash_profile '[ -s "/usr/local/opt/nvm/nvm.sh" ] && . "/usr/local/opt/nvm/nvm.sh"  # This loads nvm'
  append_to_bash_profile '[ -s "/usr/local/opt/nvm/etc/bash_completion" ] && . "/usr/local/opt/nvm/etc/bash_completion"  # This loads nvm bash_completion'

  export NVM_DIR="$HOME/.nvm"
  # shellcheck disable=SC1091
  source "/usr/local/opt/nvm/nvm.sh"

  nvm install "$NODE_VERSION"

  nvm alias default "$DEFAULT_NODE_VERSION"
  log "✅ Nodejs installed"

  # install yarn
  log "⚠️  Installing Yarn"
  curl -o- -L https://yarnpkg.com/install.sh | bash -s -- --version "$YARN_VERSION"
  log "✅ Yarn installed"
}

create_ssh_key() {
  if [ -f "$SSH_KEY" ]; then
    log "✅ ssh key already exists at $SSH_KEY"
  else
    log "⚠️  Creating SSH key"
    ssh-keygen -t rsa -b 4096 -f "$SSH_KEY" -N ""
    log "✅ SSH key created at $SSH_KEY"
  fi
}

configure_ssh() {
  local header="# BEGIN ADDED BY BOOTSTRAP"
  local footer="# END ADDED BY BOOTSTRAP"
  log "⚠️  Configuring SSH"

  # remove anything previously added by bootstrap
  if [ -f "$SSH_CONFIG" ]; then
    < "$SSH_CONFIG" tr '\n' ';;' | \
      sed -E "s/$header(.*)$footer//" | \
      tr ';;' '\n' > "$SSH_CONFIG.tmp"
  fi

  {
    echo "$header"
    cat ./files/ssh_config
    echo "$footer"
  } >> "$SSH_CONFIG.tmp"

  mv "$SSH_CONFIG.tmp" "$SSH_CONFIG"
  log "✅ SSH configured"
}

install_homebrew
brew_bundle
launch_docker
install_aws
install_ruby
install_nodejs
create_ssh_key
configure_ssh
