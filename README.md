# Bootstrap

Bootstrap your laptop into a lean, mean, software-shipping dev machine.

## Requirements

* macOS

  Ideally make sure macOS is up to date (this could take a while)
  ```sh
  sudo softwareupdate -i -a --restart
  ```
* Install Xcode
  ```sh
  xcode-select --install
  ```

## Usage

> **Always review a script before running it!** See the [Info](#info) section below and review the source code in [bootstrap.sh](/bootstrap.sh)

```sh
git clone https://github.com/codecademy-engineering/bootstrap.git
cd bootstrap
./bootstrap.sh | tee -a bootstrap.log
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
  * [aws-vault](https://github.com/99designs/aws-vault) for securly storing and accessing AWS credentials
* installs [aws-cli](https://aws.amazon.com/cli/)
* installs the required Ruby & Bundler versions in `rbenv`
* installs the required Nodejs & Yarn versions in `nvm`
* creates a default ssh key at `~/.ssh/id_rsa`
* creates a recommended ssh config at `~/.ssh/config`

## References

Inspired by github.com/thoughtbot/laptop
