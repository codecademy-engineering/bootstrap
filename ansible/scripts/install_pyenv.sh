#!/usr/bin/env bash

usage() { echo "Usage: $0 [-v PYTHON_VERSION] -d" 1>&2; }

while getopts "v:d" options; do
    case "${options}" in
        v)
            PYTHON_VERSION=${OPTARG}
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
    echo "PYTHON_VERSION: ${PYTHON_VERSION}"
fi

if [ -z "${PYTHON_VERSION}" ]; then
    usage
    exit 1
fi

if [[ "${SHELL}" = "/bin/bash" ]]; then
    export PROFILE="${HOME}/.bash_profile"
elif [[ "${SHELL}" = "/bin/zsh" ]]; then
    export PROFILE="${HOME}/.zshrc"
fi

if ! grep -q "pyenv init" ${PROFILE}; then
    echo -e 'if command -v pyenv 1>/dev/null 2>&1; then\n  eval "$(pyenv init -)"\nfi' >> ${PROFILE}
fi

if ! grep -q "PYENV_ROOT" ${PROFILE}; then
    echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ${PROFILE}
    echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ${PROFILE}
fi

eval ". ${PROFILE}"
eval "$(pyenv init -)"
pyenv install ${PYTHON_VERSION}
pyenv shell ${PYTHON_VERSION}
python --version
pyenv versions
echo "Python ${PYTHON_VERSION} installed."
exit 0
