#!/usr/bin/env bash
set -eu

cat << EOF

□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□
□■□□□□■■■□■■■■■■■□□■■■□■■■□□■■■■■■■□□□□■■■□■□□■■■■□□□□□□□■■■□□□□■■■□□■■■□■■■■■□□□
□■■□□□□■□□□■□□□□■□□□■□□□■□□□■□□■□□■□□□■□□□■■□□□■□□□□□□□□■□□□■□□□□■□□□□■□□□■□□□■□□
□■□■□□□■□□□■□□□□■□□□■□□□■□□□■□□■□□■□□□■□□□□■□□□■□□□□□□□■□□□□□■□□□■□□□□■□□□■□□□■□□
□■□■□□□■□□□■□□□□□□□□□■□■□□□□□□□■□□□□□■□□□□□□□□□■□□□□□□□■□□□□□■□□□■□□□□■□□□■□□□□■□
□■□■□□□■□□□■□□■□□□□□□■□■□□□□□□□■□□□□□■□□□□□□□□□■□□□□□□□■□□□□□■□□□■□□□□■□□□■□□□□■□
□■□□■□□■□□□■□□■□□□□□□□■□□□□□□□□■□□□□□■□□□□□□□□□■□□□□□□□■□□□□□■□□□■□□□□■□□□■□□□□■□
□■□□■□□■□□□■■■■□□□□□□■□■□□□□□□□■□□□□□■□□□□□□□□□■□□□□□□□■□□□□□■□□□■□□□□■□□□■□□□□■□
□■□□■□□■□□□■□□■□□□□□□■□■□□□□□□□■□□□□□■□□□□□□□□□■□□□□□□□■□□□□□■□□□■□□□□■□□□■□□□□■□
□■□□□■□■□□□■□□■□□□□□□■□■□□□□□□□■□□□□□■□□□□□□□□□■□□□□□□□■□□□□□■□□□■□□□□■□□□■□□□□■□
□■□□□■□■□□□■□□□□■□□□■□□□■□□□□□□■□□□□□■□□□□□■□□□■□□□□■□□■□□□□□■□□□■□□□□■□□□■□□□□■□
□■□□□■□■□□□■□□□□■□□□■□□□■□□□□□□■□□□□□□■□□□□■□□□■□□□□■□□■□□□□□■□□□■□□□□■□□□■□□□■□□
□■□□□□■■□□□■□□□□■□□■□□□□□■□□□□□■□□□□□□■□□□□■□□□■□□□□■□□□■□□□■□□□□■□□□□■□□□■□□□■□□
□■■□□□□■□□■■■■■■■□□■■□□□■■□□□■■■■■□□□□□■■■■□□□■■■■■■■□□□□■■■□□□□□□■■■■□□□■■■■■□□□
□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□
by docker

EOF

# Setup

declare -r SCRIPT_DIR=$(cd $(dirname ${BASH_SOURCE:-$0}); pwd)
declare -r SCRIPT_NAME=$(basename "${0}")
declare -r SCRIPT_PATH=${SCRIPT_DIR}/${SCRIPT_NAME}
declare -r DATA_DIR=${SCRIPT_DIR}/ncdata
declare -r CONFIG_YML=${DATA_DIR}/config.yml
declare -r DOCKER_DIR=${DATA_DIR}/ncdocker
declare -r DOCKER_COMPOSE_YML=${DOCKER_DIR}/docker-compose.yml

declare -r REPOSITORY_OWNER=kensyo
declare -r REPOSITORY_NAME=introducing-script-for-nextcloud
declare -r REPOSITORY_BRANCH=main
declare -r GITHUB_BASE_URL="https://raw.githubusercontent.com/${REPOSITORY_OWNER}/${REPOSITORY_NAME}/${REPOSITORY_BRANCH}"
declare -r TAR_BALL_URL="https://github.com/${REPOSITORY_OWNER}/${REPOSITORY_NAME}/archive/${REPOSITORY_BRANCH}.tar.gz"

declare -r VERSION=v11

echo "SCRIPT VERSION: ${VERSION}"

if type docker > /dev/null 2>&1; then
    docker --version
else
    echo "Install docker." 1>&2
    exit 1
fi

if type docker-compose > /dev/null 2>&1; then
    docker-compose --version
else
    echo "Install docker-compose." 1>&2
    exit 1
fi

echo ""

# Functions
function listCommands() {
cat << "EOT"
Available commands:

install
start
stop
restart
update
updateDockerConfs
rebuild
updateself
help

EOT
}

function downloadSelf() {
    if curl -s -w "http_code %{http_code}" -o ${SCRIPT_PATH}.temp ${GITHUB_BASE_URL}/nextcloud.sh | grep -q "^http_code 20[0-9]"; then
        mv ${SCRIPT_PATH}.temp ${SCRIPT_PATH}
        chmod u+x ${SCRIPT_PATH}
        echo "Updated self."
    else
        rm -f ${SCRIPT_PATH}.temp
        echo "Update failed. Http Status Code was not 20X." 1>&2
        exit 1
    fi
}

function checkDataDirectory() {
    if [ ! -d "${DATA_DIR}" ]; then
        echo "The data directory does not exist. First install nextcloud." 1>&2
        exit 1
    fi
}

function buildDockerImages() {
    local -r PULL_FLAG=${1:-"withpull"}

    local -r SETUP_DOCKER_DIR=$(mktemp -d)
    trap "final ${SETUP_DOCKER_DIR}" SIGINT EXIT SIGKILL

    curl -L ${TAR_BALL_URL} | tar xvz -C ${SETUP_DOCKER_DIR}

    export COMPOSE_FILE=${SETUP_DOCKER_DIR}/${REPOSITORY_NAME}-${REPOSITORY_BRANCH}/docker/docker-compose.yml

    if [ "${PULL_FLAG}" = "withpull" ]; then
        docker-compose build --pull
    else
        docker-compose build
    fi

    export COMPOSE_FILE=""
}

function final() {
    local -r DIR=${1}
    if [ -d "${DIR}" ]; then
        rm -rf ${DIR}
    fi
}

function serveNCContainers() {
    local -r TYPE=${1}

    export COMPOSE_FILE=${DOCKER_COMPOSE_YML}

    if [ "${TYPE}" = "start" ]; then
        docker-compose up -d
    elif [ "${TYPE}" = "stop" ]; then
        if [ $(docker-compose ps | wc -l) -gt 2 ]; then
            docker-compose down
        fi
    fi

    export COMPOSE_FILE=""
}

function waitUntilInstalled() {
    # TODO: 最大ループ回数は決めておいたほうが良い
    echo "Waiting for nextcloud to be initialized..."
    sleep 30
    while :
    do
        if grep -q "'installed' => true" ${DATA_DIR}/web/config/config.php > /dev/null 2>&1; then
            break
        fi
        sleep 5
    done
}

# Commands

case ${1:-""} in
    "install")
        if [ -e "${CONFIG_YML}" ]; then
            echo "Nextcloud has already been installed."
            exit 0
        fi
        mkdir -p ${DATA_DIR}
        buildDockerImages withpull
        docker run --rm -it -v ${DATA_DIR}:/ncdata kensyo/ncsetup install
        serveNCContainers start
        waitUntilInstalled
        serveNCContainers stop
        docker run --rm -v ${DATA_DIR}:/ncdata kensyo/ncsetup update
        docker run --rm -v ${DATA_DIR}:/ncdata kensyo/ncconfigure
        echo "Nextcloud successfully installed."
        echo 'Modify ncdata/config.yml and run `./nextcloud.sh rebuild` if you need, and then, run `./nextcloud start`'
        ;;
    "start")
        checkDataDirectory
        serveNCContainers start
        ;;
    "stop")
        checkDataDirectory
        serveNCContainers stop
        ;;
    "restart")
        checkDataDirectory
        serveNCContainers stop
        serveNCContainers start
        ;;
    "update")
        checkDataDirectory
        serveNCContainers stop
        export COMPOSE_FILE=${DOCKER_COMPOSE_YML}
        docker-compose pull
        docker-compose build --pull
        export COMPOSE_FILE=""
        echo "Now restart nextcloud."
        ;;
    "updateDockerConfs")
        checkDataDirectory
        serveNCContainers stop
        buildDockerImages withpull
        docker run --rm -v ${DATA_DIR}:/ncdata kensyo/ncsetup update
        docker run --rm -v ${DATA_DIR}:/ncdata kensyo/ncconfigure
        echo "Successfully updated docker configurations."
        echo "Now restart nextcloud."
        ;;
    "rebuild")
        checkDataDirectory
        serveNCContainers stop
        # buildSetupDockerImage nopull
        docker run --rm -v ${DATA_DIR}:/ncdata kensyo/ncsetup update
        docker run --rm -v ${DATA_DIR}:/ncdata kensyo/ncconfigure
        echo "Successfully rebuilt."
        echo "Now restart nextcloud."
        ;;
    "updateself")
        downloadSelf
        ;;
    "help")
        listCommands
        ;;
    *)
        echo "No command found."
        echo
        listCommands
esac
