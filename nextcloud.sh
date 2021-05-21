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
changedbsetup
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
    trap "rm -rf ${SETUP_DOCKER_DIR}" SIGINT EXIT SIGKILL SIGHUP

    curl -L ${TAR_BALL_URL} | tar xvz -C ${SETUP_DOCKER_DIR}

    export COMPOSE_FILE=${SETUP_DOCKER_DIR}/${REPOSITORY_NAME}-${REPOSITORY_BRANCH}/docker/docker-compose.yml

    if [ "${PULL_FLAG}" = "withpull" ]; then
        docker-compose build --pull
    else
        docker-compose build
    fi

    export COMPOSE_FILE=""
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

function inputEnv() {
    local -r PROMPT_MESSAGE=${1}
    local -r ENV_NAME=${2}
    local -r IS_SECRET=${3:-0} # 0 is false and 1 is true
    local -r CONFIRMATION=${4:-0} # 0 is false and 1 is true

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

        if [ ! "${CONFIRMATION}" -eq 0 ]; then
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

function changeDBSetup() {
    local -ar OPTIONS=(
        "MYSQL root password"
        "MYSQL database name"
        "MYSQL user name"
        "MYSQL user password"
    )

    echo ""
    for ((i = 0; i < ${#OPTIONS[@]}; i++)) {
        echo "[$i]: ${OPTIONS[i]}"
    }

    local index=0
    while :
    do
        inputEnv "Which do you change? [0..$(( ${#OPTIONS[@]} - 1 ))]: " index
        if [ 0 -le ${index} -a ${index} -lt ${#OPTIONS[@]} ]; then
            break
        else
            echo "Choose out of [0..$(( ${#OPTIONS[@]} - 1 ))]"
        fi
    done
    echo ""

    case ${OPTIONS[${index}]} in
        "MYSQL root password")
            local  currentPassword=""
            local newPassword=""
            inputEnv "Enter the current password: " currentPassword 1
            inputEnv "Enter a new password: " newPassword 1 1

            export COMPOSE_FILE=${DOCKER_COMPOSE_YML}
            docker-compose up -d db
            sleep 1
            docker-compose exec db bash -c "mysql --defaults-file=<( printf '[client]\npassword=%s\nexecute=ALTER USER \"root\"@\"localhost\" IDENTIFIED BY \"%s\"\n' ${currentPassword} ${newPassword} ) -uroot mysql"
            # docker-compose exec db bash -c "mysql --defaults-file=<( printf '[client]\npassword=%s\nexecute=ALTER USER \"root\"@\"%%\" IDENTIFIED BY \"%s\"\n' ${currentPassword} ${newPassword} ) -uroot mysql"
            docker-compose down
            export COMPOSE_FILE=""
            ;;
        "MYSQL database name")
            ;;
        "MYSQL user name")
            ;;
        "MYSQL user password")
            #### 1. socket サーバを建てる
            #### 2. configure を起動する。中でconfig を書き換えて、user名をsocketサーバに送信。
            #### 3. サーバはホスト名を受け取ったら下を実行する。
            #### 4. pid なくなるまでまつ
            # 1. php コンテナーでconfig書き換えて、ファイルにdbホストの名前を記述
            # 2. このスクリプト内側でパスワード変更
  # 'dbname' => 'fugu',
  # 'dbhost' => 'db',
  # 'dbuser' => 'fugu',
  # 'dbpassword' => 'fugu',
            local rootPassword=""
            local newPassword=""
            inputEnv "Enter MYSQL root password: " rootPassword 1
            inputEnv "Enter a new MYSQL user password: " newPassword 1 1

            local -r TMP_DIR=$(mktemp -d)
            trap "rm -rf ${TMP_DIR}" SIGINT EXIT SIGKILL SIGHUP

            local -r TMP_FILE_PATH=${TMP_DIR}/dbuser.txt
            touch ${TMP_FILE_PATH}

            docker run --rm -v ${DATA_DIR}:/ncdata -v ${TMP_FILE_PATH}:/tmp/info.txt kensyo/ncconfigure reconfigure dbpassword ${newPassword}

            local -r DB_USER=$(cat ${TMP_FILE_PATH})
            rm -rf ${TMP_DIR}

            export COMPOSE_FILE=${DOCKER_COMPOSE_YML}
            docker-compose up -d db
            sleep 1
            docker-compose exec db bash -c "mysql --defaults-file=<( printf '[client]\npassword=%s\nexecute=ALTER USER \"${DB_USER}\"@\"%%\" IDENTIFIED BY \"%s\"\n' ${rootPassword} ${newPassword} ) -uroot mysql"
            docker-compose down
            export COMPOSE_FILE=""
            echo "MYSQL user password has successfully been changed."
            ;;
        *)
            echo "Something wrong." 1>&2
            exit 1
            ;;
    esac
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
        docker run --rm -v ${DATA_DIR}:/ncdata kensyo/ncconfigure configure
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
        docker run --rm -v ${DATA_DIR}:/ncdata kensyo/ncconfigure configure
        echo "Successfully updated docker configurations."
        echo "Now restart nextcloud."
        ;;
    "rebuild")
        checkDataDirectory
        serveNCContainers stop
        # buildSetupDockerImage nopull
        docker run --rm -v ${DATA_DIR}:/ncdata kensyo/ncsetup update
        docker run --rm -v ${DATA_DIR}:/ncdata kensyo/ncconfigure configure
        echo "Successfully rebuilt."
        echo "Now restart nextcloud."
        ;;
    "changedbsetup")
        checkDataDirectory
        # serveNCContainers stop
        changeDBSetup
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
