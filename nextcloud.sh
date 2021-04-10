#!/usr/bin/env bash
set -u

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
declare -r SCRIPT_PATH="${SCRIPT_DIR}/${SCRIPT_NAME}"
declare -r DATA_DIR="${SCRIPT_DIR}/ncdata"
declare -r YML=${DATA_DIR}/ncdocker/docker-compose.yml

declare -r GITHUB_BASE_URL="https://raw.githubusercontent.com/kensyo/introducing-script-for-nextcloud/master"

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

echo

# Functions

function listCommands() {
cat << "EOT"
Available commands:

install
start
stop
restart
update
updateself
help

EOT
}

function downloadSelf() {
    if curl -s -w "http_code %{http_code}" -o ${SCRIPT_PATH}.temp ${GITHUB_BASE_URL}/nextcloud.sh | grep -q "^http_code 20[0-9]"; then
        mv ${SCRPT_PATH}.temp ${SCRIPT_PATH}
        chmod u+x ${SCRIPT_PATH}
    else
        rm -f ${SCRIPT_PATH}.temp
    fi
}

function checkDataDirectory() {
    if [ ! -d "${DATA_DIR}" ]; then
        echo "The data directory does not exist. First install nextcloud."
        exit 1
    fi
}

function setComposeFile() {
    export COMPOSE_FILE=${YML}
}

function inputEnv() {
    local -r PROMPT_MESSAGE=${1}
    local -r ENV_NAME=${2}
    local -r IS_SECRET=${3:-0} # 0 is false and 1 is true

    while :
    do
        if [ "${IS_SECRET}" -eq 0 ]; then
            read -p "${PROMPT_MESSAGE}" input
        else
            read -sp "${PROMPT_MESSAGE}" input
            tty -s && echo "" # -s つけると改行がいるっぽい
        fi

        if [ -z "${input}" ]; then
            echo "An empty value must not be set. Type again." 1>&2
            continue
        fi

        if [ ! "${IS_SECRET}" -eq 0 ]; then
            read -sp "Input again for confirmation: " confirmationInput
            tty -s && echo "" # -s つけると改行がいるっぽい
            if [ "${input}" != "${confirmationInput}" ]; then
                echo "Does not coincide. Type again." 1>&2    
                continue
            fi
        fi

        eval ${ENV_NAME}=${input}
        break
    done
 
}

function createDockerComposeYml() {

    inputEnv "Enter MYSQL_ROOT_PASSWORD: " MYSQL_ROOT_PASSWORD 1
    inputEnv "Enter MYSQL_PASSWORD: " MYSQL_PASSWORD 1
    inputEnv "Enter MYSQL_DATABASE(e.g. nextcloud): " MYSQL_DATABASE
    inputEnv "Enter MYSQL_USER(e.g. nextcloud): " MYSQL_USER
    inputEnv "Enter MYSQL_HOST(e.g. nextcloud): " MYSQL_HOST

    mkdir -p ${DATA_DIR}/ncdocker

cat <<- EOF > ${YML}
version: '2'

services:
  db:
    image: mariadb
    restart: always
    command: --transaction-isolation=READ-COMMITTED --binlog-format=ROW
    volumes:
      - ../db:/var/lib/mysql
    environment:
      - MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
      - MYSQL_PASSWORD=${MYSQL_PASSWORD}
      - MYSQL_DATABASE=${MYSQL_DATABASE}
      - MYSQL_USER=${MYSQL_USER}

  app:
    image: nextcloud
    restart: always
    ports:
      - 8080:80
    links:
      - db
    volumes:
      - ../web:/var/www/html
    environment:
      - MYSQL_PASSWORD=${MYSQL_PASSWORD}
      - MYSQL_DATABASE=${MYSQL_DATABASE}
      - MYSQL_USER=${MYSQL_USER}
      - MYSQL_HOST=${MYSQL_HOST}
EOF
}

# Commands

case ${1:-""} in
    "install")
        if [ -d "${DATA_DIR}" ]; then
            echo "${DATA_DIR} already exists"
            exit 1
        fi
        createDockerComposeYml
        ;;
    "start")
        checkDataDirectory
        setComposeFile
        docker-compose up -d
        ;;
    "stop")
        checkDataDirectory
        setComposeFile
        docker-compose down
        ;;
    "restart")
        checkDataDirectory
        setComposeFile
        docker-compose down
        docker-compose up -d
        ;;
    "update")
        checkDataDirectory
        setComposeFile
        docker-compose pull
        echo "Now restart nextcloud."
        ;;
    "updateself")
        downloadSelf
        echo "Updated self."
        ;;
    "help")
        listCommands
        ;;
    *)
        echo "No command found."
        echo
        listCommands
esac
