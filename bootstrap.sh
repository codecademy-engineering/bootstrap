#!/usr/bin/env sh

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

# Note there's currently no sane way to programmatically find a previous
# formula SHA by version number (unfortunately). See:
# - https://docs.brew.sh/Versions.html
# - https://github.com/syhw/homebrew/blob/master/Library/Contributions/example-formula.rb
#
# Beware of various stackoverflow/exchange answers referencing the deprecated
# Homebrew/versions repository (notably https://stackoverflow.com/a/4158763).
# However that post has a good info on how to find the SHA you need 📄
pin_forumla() {
  formula="$1"
  version="$2"
  sha="$3"
  brew unpin "$formula" 2>/dev/null || true
  brew unlink "$formula" 2>/dev/null || true
  brew install https://raw.githubusercontent.com/Homebrew/homebrew-core/"${sha}"/Formula/"${formula}".rb
  brew switch "$formula" "$version"
  brew pin "$formula"
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
  append_to_dotfiles "eval \"$(rbenv init -)\""

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

# Temporary shim to address https://codecademy.atlassian.net/browse/DEVOPS-1235
# To-do: Remove this function in favor of Brewfile once Helm v3 is GA and in
#   homebrew. ETA planning a 3.0 GA release before KubeCon San Diego
#   Nov/18/2019.
pin_helm() {
  pin_forumla kubernetes-helm 2.14.3 0a17b8e50963de12e8ab3de22e53fccddbe8a226
}

initialize_helm() {
  helm init --client-only
  mkdir -p "$(helm home)/plugins"
  helm plugin install https://github.com/databus23/helm-diff --version master 2>/dev/null || true
}

# Until we fully adopt Helm v3, install 'helm3' (v3) alongside 'helm' (v2).
# Once v3.0.0 is released, the Homebrew formula will be updated and we can
# unpin when we're ready.
install_helm3() {
  helm_version=v3.0.0-rc.3
  curl -sSLO "https://get.helm.sh/helm-$helm_version-darwin-amd64.tar.gz"
  sudo mkdir -p "/usr/local/helm-$helm_version"
  sudo tar -xzf "helm-$helm_version-darwin-amd64.tar.gz" -C "/usr/local/helm-$helm_version"
  sudo ln -sf "/usr/local/helm-$helm_version/darwin-amd64/helm" /usr/local/bin/helm3
  rm "helm-$helm_version-darwin-amd64.tar.gz"

  # helm3 plugins
  if ! helm3 plugin update diff 2>/dev/null; then
    helm3 plugin install https://github.com/databus23/helm-diff
  fi
  if ! helm3 plugin update namespace 2>/dev/null; then
    helm3 plugin install https://github.com/thomastaylor312/helm-namespace
  fi
}

log "⚠️  Beginning Bootstrap"

install_homebrew
brew_bundle
launch_docker
install_ruby
install_nodejs
git_config
create_ssh_key
configure_ssh
k8s_completion
pin_helm
initialize_helm
install_helm3

log "✅ Bootstrap Complete 🚀🚀🚀"
