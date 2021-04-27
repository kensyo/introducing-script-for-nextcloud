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
declare -r SCRIPT_PATH=${SCRIPT_DIR}/${SCRIPT_NAME}
declare -r DATA_DIR=${SCRIPT_DIR}/ncdata
declare -r DOCKER_DIR=${DATA_DIR}/ncdocker
declare -r APP_DOCKER_FILE_DIR=${DOCKER_DIR}/app
declare -r APP_DOCKER_FILE_PATH=${APP_DOCKER_FILE_DIR}/Dockerfile
declare -r YML=${DOCKER_DIR}/docker-compose.yml

declare -r GITHUB_BASE_URL="https://raw.githubusercontent.com/kensyo/introducing-script-for-nextcloud/main"

declare -r VERSION=v9

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
reinstall
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

function createAppDockerfile() {
    mkdir -p ${APP_DOCKER_FILE_DIR}

cat <<-EOF > ${APP_DOCKER_FILE_PATH}
FROM nextcloud

# for thumbnails
# references:
# https://help.nextcloud.com/t/cant-see-pdf-thumbnails-in-new-grid-view-but-works-in-the-demo-instance/43759
# https://help.nextcloud.com/t/pdf-previews-are-not-generated/51942
RUN apt-get update
RUN apt-get install -y ghostscript ffmpeg imagemagick
RUN sed -i 's#<policy domain="coder" rights="none" pattern="PDF" />#<policy domain="coder" rights="read|write" pattern="PDF" />#' /etc/ImageMagick-6/policy.xml

# for background jobs
# references:
# https://help.nextcloud.com/t/solved-occ-command-php-fatal-error-allowed-memory-size-of-xxx-bytes-exhausted/108521/29
RUN sed -i 's#\*/5 \* \* \* \* php -f /var/www/html/cron.php#*/5 * * * * PHP_MEMORY_LIMIT=512M /usr/local/bin/php -f /var/www/html/cron.php#' /var/spool/cron/crontabs/www-data
RUN apt-get install -y cron
RUN crontab -u www-data /var/spool/cron/crontabs/www-data

ENTRYPOINT sh -c "service cron start && /entrypoint.sh apache2-foreground"

EOF
}

function createDockerComposeYml() {

    inputEnv "Enter MYSQL_ROOT_PASSWORD: " MYSQL_ROOT_PASSWORD 1
    inputEnv "Enter MYSQL_PASSWORD: " MYSQL_PASSWORD 1
    inputEnv "Enter MYSQL_DATABASE(e.g. nextcloud): " MYSQL_DATABASE
    inputEnv "Enter MYSQL_USER(e.g. nextcloud): " MYSQL_USER
    inputEnv "Enter PORT(e.g. 8080): " PORT

    mkdir -p ${DOCKER_DIR}

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
    build: ./$(basename ${APP_DOCKER_FILE_DIR})
    restart: always
    ports:
      - ${PORT}:80
    links:
      - db
    volumes:
      - ../web:/var/www/html
    environment:
      - MYSQL_PASSWORD=${MYSQL_PASSWORD}
      - MYSQL_DATABASE=${MYSQL_DATABASE}
      - MYSQL_USER=${MYSQL_USER}
      - MYSQL_HOST=db
EOF
}

# Commands

case ${1:-""} in
    "install")
        if [ -d "${DATA_DIR}" ]; then
            echo "${DATA_DIR} already exists."
            exit 1
        fi
        createAppDockerfile
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
        docker-compose pull && docker-compose build --pull && echo "Now restart nextcloud."
        ;;
    "reinstall")
        checkDataDirectory
        if [ -d "${DOCKER_DIR}" ]; then
            echo "Remove and recreate docker configurations?"
            read -p "(This operation doesn't give any change to your stored data.) (y/n): " ans
            if [ ! "${ans}" = 'y' ]; then
                exit 0
            fi
            rm -rf ${DOCKER_DIR}
        else
            echo "The docker directory not found."
            read -p "Create it newly? (y/n): " ans
            if [ ! "${ans}" = 'y' ]; then
                exit 0
            fi
        fi
        # create
        createAppDockerfile
        createDockerComposeYml
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
