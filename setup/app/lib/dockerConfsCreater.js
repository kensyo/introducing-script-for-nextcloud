'use strict'

module.exports = {
    createDockerComposeYml
};

// public
function createDockerComposeYml() {
    const util = require('./utility');
    const CONFIG = util.loadConfig();
    const DATA_DIR = CONFIG['DATA_DIR'];
    const NC_CONFIG = util.loadYml(`${DATA_DIR}/config.yml`); // TODO: validation
    const DOCKER_DIR = `${DATA_DIR}/${CONFIG['DOCKER_DIR_RELATIVE_PATH']}`;
    const fs = require('fs-extra');
    const CUSTOM_DOCKER_FILE_RELATIVE_PATH = CONFIG['CUSTOM_DOCKER_FILE_RELATIVE_PATH'];
    const path = require('path');

    let IMAGE_OR_BUILD = null;
    if (fs.existsSync(`${DOCKER_DIR}/${CUSTOM_DOCKER_FILE_RELATIVE_PATH}`)) {
        IMAGE_OR_BUILD =
`build:
      context: ${path.dirname(CUSTOM_DOCKER_FILE_RELATIVE_PATH)}
      dockerfile: ${path.basename(CUSTOM_DOCKER_FILE_RELATIVE_PATH)}`;
    } else {
        IMAGE_OR_BUILD =
`# If you want to use a custom nextcloud docker image,
    # create ${CONFIG['CUSTOM_DOCKER_FILE_RELATIVE_PATH']} in the same directory as this file.
    # Then run ./nextcloud rebuild.
    image: nextcloud`;
    }
    let replacementWords = {
        MYSQL_ROOT_PASSWORD: NC_CONFIG['MYSQL_ROOT_PASSWORD'],
        MYSQL_DATABASE: NC_CONFIG['MYSQL_DATABASE'],
        MYSQL_PASSWORD: NC_CONFIG['MYSQL_PASSWORD'],
        MYSQL_USER: NC_CONFIG['MYSQL_USER'],
        PORT: NC_CONFIG['PORT'],
        IMAGE_OR_BUILD: IMAGE_OR_BUILD,
    };
    let templateToRead = null;
    const PROXY_DOCKER_FILE_RELATIVE_PATH = CONFIG['PROXY_DOCKER_FILE_RELATIVE_PATH'];
    if (NC_CONFIG.hasOwnProperty('SSL')) {
        templateToRead = 'files/ssl-docker-compose.yml.template';
        replacementWords['VIRTUAL_HOST'] = NC_CONFIG['SSL']['VIRTUAL_HOST'];
        replacementWords['SSL_PORT'] = NC_CONFIG['SSL']['PORT'];
        replacementWords['BUILD_PROXY'] =
`build:
      context: ${path.dirname(PROXY_DOCKER_FILE_RELATIVE_PATH)}
      dockerfile: ${path.basename(PROXY_DOCKER_FILE_RELATIVE_PATH)}`;
        fs.copySync('files/proxy', `${DOCKER_DIR}/${path.dirname(PROXY_DOCKER_FILE_RELATIVE_PATH)}`);
    } else {
        templateToRead = 'files/docker-compose.yml.template';

        // No problem even if the file doesn't exist.
        fs.removeSync(`${DOCKER_DIR}/${path.dirname(PROXY_DOCKER_FILE_RELATIVE_PATH)}`);
    }
    const dcTemplate = fs.readFileSync(templateToRead, 'utf-8');
    const yml = util.template(
        dcTemplate,
        replacementWords
    );
    try {
        fs.mkdirSync(DOCKER_DIR);
    } catch (err) {
        if (err.code !== "EEXIST") {
            throw err;
        }
    }
    fs.writeFileSync(`${DOCKER_DIR}/docker-compose.yml`, yml, 'utf8');
}
