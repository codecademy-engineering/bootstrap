# Bootstrap

[![CircleCI](https://circleci.com/gh/codecademy-engineering/bootstrap/tree/master.svg?style=shield)](https://circleci.com/gh/codecademy-engineering/bootstrap/tree/master)

Bootstrap your laptop into a lean, mean, software-shipping dev machine.

## Requirements

* macOS

  Ideally make sure macOS is up to date (this could take a while)
  ```sh
  sudo softwareupdate -i -a
  ```
* Xcode
  ```sh
  xcode-select --install
  ```

RESTART AFTER RUNNING THE ABOVE. After restarting, verify in the `Software and Updates` App that your Mac has no pending updates. If it does, install them and reboot again.

* Bash or Zsh

  The bootstrap script assumes you use bash or zsh and adds required configuration to `~/.bash_profile` and `~/.zshrc` respectively.
  If using another shell, e.g. zsh, you'll need to accommodate that yourself.

## Usage

> **Always review a script before running it!** See the [Info](#info) section below and review the source code in [bootstrap.sh](/bootstrap.sh)

```sh
git clone https://github.com/codecademy-engineering/bootstrap.git
cd bootstrap
./bootstrap.sh | tee -a bootstrap.log
```

It should print `✅ Bootstrap Complete 🚀🚀🚀` upon completion.

After bootstrapping you may need to source your shell profile to get new environment configurations:

### Zsh (default shell for Catalina)
```sh
source ~/.zshrc
```

### Bash
```sh
source ~/.bash_profile
```

## Info

[bootstrap.sh](/bootstrap.sh) does the following:

* installs [Homebrew](https://brew.sh), the package manager of choice for macOS
* uses Homebrew to install packages from [the Brewfile](/files/Brewfile), which include:
  * [rbenv](https://github.com/rbenv/rbenv) for managing Ruby versions
  * [nvm](https://github.com/nvm-sh/nvm) for managing Nodejs versions
  * [Go](https://golang.org/)
  * [Python 3.x](https://www.python.org/)
  * [Docker](https://www.docker.com/)
  * [kubectl](https://kubernetes.io/), [helm](https://helm.sh/), [helmfile](https://github.com/roboll/helmfile), and [kubectx](https://github.com/ahmetb/kubectx) for working with Kubernetes
  * [awscli](https://aws.amazon.com/cli/) and [aws-vault](https://github.com/99designs/aws-vault) for securly accessing AWS
* installs the required Ruby & Bundler versions in `rbenv`
* installs the required Nodejs & Yarn versions in `nvm`
* creates a default ssh key at `~/.ssh/id_rsa`
* creates a recommended ssh config at `~/.ssh/config`
* initializes `helm` client and the helpful [helm-diff](https://github.com/databus23/helm-diff) plugin

## Bash on Catalina

As of MacOS Catalina (10.15), `bash` is no longer the default shell. The default shell going forward is `zsh`.
If you want to continue to use `bash`, change your default shell:

```sh
# Path to current bash binary installed with homebrew by bootstrap.sh
chsh -s /usr/local/bin/bash
```

After this, close and reopen Terminal. It will be running `bash` as the default shell. For more info see [HT208050](https://support.apple.com/en-us/HT208050).

## Troubleshooting

* Error running `bundle install` for `pg` gem

The following error was reported on `MacOS v10.15.7/xcode-select v2373/Ruby 1.5.8/bundler 1.17.3` attempting to run `bundle install`, specifically the `pg -v '0.17.1'` gem.

```console
pg_connection.c:2323:3: error: implicit declaration of function 'gettimeofday' is invalid in C99
[-Werror,-Wimplicit-function-declaration]
        gettimeofday(&currtime, NULL);
        ^
pg_connection.c:2340:4: error: implicit declaration of function 'gettimeofday' is invalid in C99
[-Werror,-Wimplicit-function-declaration]
            gettimeofday(&currtime, NULL);
            ^
2 errors generated.
make: *** [pg_connection.o] Error 1
make failed, exit code 2

. . .

An error occurred while installing pg (0.17.1), and Bundler cannot continue.
Make sure that `gem install pg -v '0.17.1' --source 'http://rubygems.org/'` succeeds before bundling
```

The fix was to run the following commad, sourced [here](https://stackoverflow.com/a/63583496")

```sh
$ gem install pg -v '0.17.1' -- --with-cflags="-Wno-error=implicit-function-declaration"
```
Afterwards, running `bundle install` should work.

If it doesn't work:
    1. Verify you are up to-date on all Software.
    2. `brew uninstall postgresql`
    3. `brew update`
    4. `brew install postgresql`
    5. `bundle install`


## References

Inspired by https://github.com/thoughtbot/laptop
