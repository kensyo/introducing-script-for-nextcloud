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
declare -r RUN_DOCKER_DIR=${DATA_DIR}/ncdocker
declare -r RUN_APP_DOCKER_FILE_DIR=${RUN_DOCKER_DIR}/app
declare -r RUN_APP_DOCKER_FILE_PATH=${RUN_APP_DOCKER_FILE_DIR}/Dockerfile
declare -r RUN_DOCKER_COMPOSE_YML=${RUN_DOCKER_DIR}/docker-compose.yml

# must remove after done or trash
declare -r SETUP_DOCKER_DIR=$(mktemp -d)
declare -r SETUP_DOCKER_COMPOSE_YML=${SETUP_DOCKER_DIR}/setup/docker-compose.yml

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

trap "final" SIGINT EXIT SIGKILL

# Functions

function final() {
    if [ -d "${SETUP_DOCKER_DIR}" ]; then
        rm -rf ${SETUP_DOCKER_DIR}
        echo "DELETED"
    fi
}

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

function setComposeFile() {
    local -r TYPE=${1}
    if [ "${TYPE}" = "setup" ]; then
        export COMPOSE_FILE=${SETUP_DOCKER_COMPOSE_YML}
    elif [ "${TYPE}" = "run" ]; then
        export COMPOSE_FILE=${RUN_DOCKER_COMPOSE_YML}
    else
        export COMPOSE_FILE=""
    fi
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

function buildSetupDockerImage() {
    local -r PULL_FLAG=${1:-"withpull"}

    curl -L ${TAR_BALL_URL} | tar xvz -C ${SETUP_DOCKER_DIR}
    setComposeFile setup
    if [ "${PULL_FLAG}" = "withpull" ]; then
        docker-compose build --pull
    else
        docker-compose build
    fi
}

# function createConfig() {
#     docker run --rm -v ${DATA_DIR}:/ncdata nextclouddocker/setup install
# }

# function createAppDockerfile() {
#     docker run --rm -v ${DATA_DIR}:/ncdata nextclouddocker/setup update
#     # mkdir -p ${RUN_APP_DOCKER_FILE_DIR}

# # cat <<-EOF > ${RUN_APP_DOCKER_FILE_PATH}
# # FROM nextcloud

# # # for thumbnails
# # # references:
# # # https://help.nextcloud.com/t/cant-see-pdf-thumbnails-in-new-grid-view-but-works-in-the-demo-instance/43759
# # # https://help.nextcloud.com/t/pdf-previews-are-not-generated/51942
# # RUN apt-get update
# # RUN apt-get install -y ghostscript ffmpeg imagemagick
# # RUN sed -i 's#<policy domain="coder" rights="none" pattern="PDF" />#<policy domain="coder" rights="read|write" pattern="PDF" />#' /etc/ImageMagick-6/policy.xml

# # # for background jobs
# # # references:
# # # https://help.nextcloud.com/t/solved-occ-command-php-fatal-error-allowed-memory-size-of-xxx-bytes-exhausted/108521/29
# # RUN sed -i 's#\*/5 \* \* \* \* php -f /var/www/html/cron.php#*/5 * * * * PHP_MEMORY_LIMIT=512M /usr/local/bin/php -f /var/www/html/cron.php#' /var/spool/cron/crontabs/www-data
# # RUN apt-get install -y cron
# # RUN crontab -u www-data /var/spool/cron/crontabs/www-data

# # ENTRYPOINT sh -c "service cron start && /entrypoint.sh apache2-foreground"

# # EOF
# }

# function createDockerComposeYml() {

#     inputEnv "Enter MYSQL_ROOT_PASSWORD: " MYSQL_ROOT_PASSWORD 1
#     inputEnv "Enter MYSQL_PASSWORD: " MYSQL_PASSWORD 1
#     inputEnv "Enter MYSQL_DATABASE(e.g. nextcloud): " MYSQL_DATABASE
#     inputEnv "Enter MYSQL_USER(e.g. nextcloud): " MYSQL_USER
#     inputEnv "Enter PORT(e.g. 8080): " PORT

#     mkdir -p ${RUN_DOCKER_DIR}

# cat <<- EOF > ${RUN_DOCKER_COMPOSE_YML}
# version: '2'

# services:
#   db:
#     image: mariadb
#     restart: always
#     command: --transaction-isolation=READ-COMMITTED --binlog-format=ROW
#     volumes:
#       - ../db:/var/lib/mysql
#     environment:
#       - MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
#       - MYSQL_PASSWORD=${MYSQL_PASSWORD}
#       - MYSQL_DATABASE=${MYSQL_DATABASE}
#       - MYSQL_USER=${MYSQL_USER}

#   app:
#     build: ./$(basename ${RUN_APP_DOCKER_FILE_DIR})
#     restart: always
#     ports:
#       - ${PORT}:80
#     links:
#       - db
#     volumes:
#       - ../web:/var/www/html
#     environment:
#       - MYSQL_PASSWORD=${MYSQL_PASSWORD}
#       - MYSQL_DATABASE=${MYSQL_DATABASE}
#       - MYSQL_USER=${MYSQL_USER}
#       - MYSQL_HOST=db
# EOF
# }

function serveNCContainers() {
    local -r TYPE=${1}

    setComposeFile run

    if [ "${TYPE}" = "start" ]; then
        docker-compose up -d
    elif [ "${TYPE}" = "stop" ]; then
        if [ $(docker-compose ps | wc -l) -gt 2 ]; then
            docker-compose down
        fi
    fi

    setComposeFile
}

# Commands

case ${1:-""} in
    "install")
        if [ -e "${CONFIG_YML}" ]; then
            echo "Nextcloud has already been installed."
            exit 1
        fi
        mkdir -p ${DATA_DIR}
        buildSetupDockerImage withpull
        docker run --rm -v ${DATA_DIR}:/ncdata kensyo/ncsetup install
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
        setComposeFile run
        docker-compose pull && docker-compose build --pull && echo "Now restart nextcloud."
        ;;
    "updateDockerConfs")
        checkDataDirectory
        buildSetupDockerImage withpull
        docker run --rm -v ${DATA_DIR}:/ncdata kensyo/ncsetup update
        ;;
    "rebuild")
        checkDataDirectory
        buildSetupDockerImage nopull
        docker run --rm -v ${DATA_DIR}:/ncdata kensyo/ncsetup update
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
