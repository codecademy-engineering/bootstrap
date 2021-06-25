#!/usr/bin/env sh

set -o errexit
set -o nounset

####################
# VARS             #
####################

RUBY_VERSION="2.7.1"
export RBENV_VERSION="$RUBY_VERSION"
BUNDLER_VERSION="2.2.17"

NODE_VERSION="12.16.0"
YARN_VERSION="1.21.1"

SSH_KEY="$HOME/.ssh/id_rsa"
SSH_CONFIG="$HOME/.ssh/config"

TERRAFORM_VERSION="0.13.4"

####################
# Helpers          #
####################

log() {
  # shellcheck disable=SC2155
  ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  fmt="$ts\t$1"; shift
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

append_to_dotfiles() {
  append_to_dotfile bash_profile "$1"
  append_to_dotfile zshrc "$1"
}

append_to_dotfile() {
  dotfile="$1"
  text="$2"
  filepath="$HOME/.$dotfile"
  if ! grep -Fxq "$text" "$filepath"; then
    log "⚠️  Appending to $dotfile:\n\t%s" "$text"
    printf "\\n%s\\n" "$text" >> "$filepath"
  else
    log "✅ $dotfile already has:\n\t%s" "$text"
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
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
    log "✅ homebrew installed"
  fi
}

# shellcheck disable=SC2016
brew_bundle() {
  log "⚠️  Installing homebrew packages from Brewfile"
  brew update && \
    brew bundle --file=./files/Brewfile

  append_to_dotfiles 'export PATH="/usr/local/opt/mongodb-community@4.0/bin:$PATH"'
  append_to_dotfiles 'export PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"'
  append_to_dotfiles 'export PATH="/usr/local/opt/gnu-sed/libexec/gnubin:$PATH"'
  append_to_dotfiles 'export PATH="/usr/local/opt/grep/libexec/gnubin:$PATH"'
  append_to_dotfiles 'export PATH="/usr/local/opt/findutils/libexec/gnubin:$PATH"'

  log "✅ Homebrew packages up to date"
}

launch_docker() {
  log "⚠️  Launching Docker"
  open /Applications/Docker.app
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

  # shellcheck disable=SC2016
  append_to_dotfiles 'eval "$(rbenv init -)"'

  log "✅ Ruby installed"
}

install_nodejs() {
  log "⚠️  Installing Nodejs"

  # nvm needs these in dotfile
  # shellcheck disable=SC2016
  append_to_dotfiles "export NVM_DIR=\"$HOME/.nvm\""
  append_to_dotfiles '[ -s "/usr/local/opt/nvm/nvm.sh" ] && . "/usr/local/opt/nvm/nvm.sh"  # This loads nvm'

  # bash autocomplete for nvm
  append_to_dotfile bash_profile '[ -s "/usr/local/opt/nvm/etc/bash_completion" ] && . "/usr/local/opt/nvm/etc/bash_completion"  # This loads nvm bash_completion'

  export NVM_DIR="$HOME/.nvm"
  # shellcheck disable=SC1091
  . "/usr/local/opt/nvm/nvm.sh"

  nvm install "$NODE_VERSION"

  nvm alias default "$NODE_VERSION"
  log "✅ Nodejs installed"

  # install yarn
  log "⚠️  Installing Yarn"
  curl -o- -L https://yarnpkg.com/install.sh | sh -s -- --version "$YARN_VERSION"
  log "✅ Yarn installed"
}

git_config() {
  git config --global url."git@github.com:".insteadOf https://github.com/
  git config --global url."git://".insteadOf https://
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
  header="# BEGIN ADDED BY BOOTSTRAP"
  footer="# END ADDED BY BOOTSTRAP"
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

# ref: https://kubernetes.io/docs/tasks/tools/install-kubectl/#enabling-shell-autocompletion
k8s_completion() {
  # Bash
  append_to_dotfile bash_profile 'export BASH_COMPLETION_COMPAT_DIR="/usr/local/etc/bash_completion.d"'
  append_to_dotfile bash_profile '[[ -r "/usr/local/etc/profile.d/bash_completion.sh" ]] && . "/usr/local/etc/profile.d/bash_completion.sh"'

  # Zsh (default shell as of MacOS Catalina)
  append_to_dotfile zshrc 'autoload -Uz compinit'
  append_to_dotfile zshrc 'compinit'
  append_to_dotfile zshrc 'source <(kubectl completion zsh)'

  # Both
  append_to_dotfiles 'alias k=kubectl'
  append_to_dotfiles 'complete -F __start_kubectl k'
}

install_helm_plugins() {
  helm plugin install https://github.com/databus23/helm-diff || true
}

# Use tfenv to manage terraform versions.
install_terraform() {
  tfenv install "$TERRAFORM_VERSION"
  tfenv use "$TERRAFORM_VERSION"
}

log "⚠️  Beginning Bootstrap"

if [ "$#" -eq "0" ]; then
  # No args passed: run the whole bootstrap
  install_homebrew
  brew_bundle
  launch_docker
  install_ruby
  install_nodejs
  git_config
  create_ssh_key
  configure_ssh
  k8s_completion
  install_helm_plugins
  install_terraform
else
  # run only the specified command, e.g. ./bootstrap.sh brew_bundle
  "$@"
fi

log "✅ Bootstrap Complete 🚀🚀🚀"
log "👉 Restart your terminal window to enjoy your bootstrapped goodness. 👈"
