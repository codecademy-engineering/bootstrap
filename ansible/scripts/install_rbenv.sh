#!/usr/bin/env bash

usage() { echo "Usage: $0 [-r RUBY_VERSION] [-b BUNDLER_VERSION] -d" 1>&2; }

while getopts "r:b:d" options; do
    case "${options}" in
        r)
            RUBY_VERSION=${OPTARG}
            ;;
        b)
            BUNDLER_VERSION=${OPTARG}
            ;;
        d)
            DEBUG=1
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [[ "${DEBUG}" = "1" ]]; then
    echo "RUBY_VERSION: ${RUBY_VERSION}"
    echo "BUNDLER_VERSION: ${BUNDLER_VERSION}"
fi

if [ -z "${RUBY_VERSION}" ] || [ -z "${BUNDLER_VERSION}" ]; then
    usage
    exit 1
fi

if ! grep -q "rbenv init" ~/.bash_profile; then
    printf "\\n%s\\n" 'eval "$(rbenv init -)"' >> ~/.bash_profile
fi
eval ". ~/.bash_profile"
eval "$(rbenv init -)"
rbenv install --skip-existing ${RUBY_VERSION}
rbenv shell ${RUBY_VERSION}
ruby --version
gem install bundler -v ${BUNDLER_VERSION}
rbenv global ${RUBY_VERSION}
rbenv rehash
rbenv versions
git clone https://github.com/rbenv/rbenv-default-gems.git $(rbenv root)/plugins/rbenv-default-gems
echo "Ruby installed."
exit 0
