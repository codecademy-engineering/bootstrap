  #!/usr/bin/env bash

usage() { echo "Usage: $0 [-n NODE_VERSION] -d" 1>&2; }

while getopts "n:d" options; do
    case "${options}" in
        n)
            NODE_VERSION=${OPTARG}
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
    echo "NODE_VERSION: ${NODE_VERSION}"
fi

export NVM_DIR="$HOME/.nvm"

. "$NVM_DIR/nvm.sh"

# TODO: For issue https://github.com/codecademy-engineering/bootstrap/issues/43:
# This should remove the old version if found (need to somehow identify the previous value)

nvm install "$NODE_VERSION"

nvm alias default "$NODE_VERSION"
