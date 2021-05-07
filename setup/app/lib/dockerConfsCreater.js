'use strict'

module.exports = {
    createDockerComposeYml
};

// public
function createDockerComposeYml() {
    const util = require('./utility');
    const CONFIG = util.loadConfig();
    const DATA_DIR = CONFIG['DATA_DIR'];
    const NC_CONFIG = util.loadYml(`${DATA_DIR}/config.yml`);
    const DOCKER_DIR = `${DATA_DIR}/${CONFIG['DOCKER_DIR_RELATIVE_PATH']}`;
    const fs = require('fs');
    const CUSTOM_DOCKER_FILE_RELATIVE_PATH = CONFIG['CUSTOM_DOCKER_FILE_RELATIVE_PATH'];

    let IMAGE_OR_BUILD = null;
    if (fs.existsSync(`${DOCKER_DIR}/${CUSTOM_DOCKER_FILE_RELATIVE_PATH}`)) {
        const path = require('path');
        IMAGE_OR_BUILD =
`build:
      context: ${path.dirname(CUSTOM_DOCKER_FILE_RELATIVE_PATH)}
      dockerfile: ${path.basename(CUSTOM_DOCKER_FILE_RELATIVE_PATH)}`;
    } else {
        IMAGE_OR_BUILD = 'image: nextcloud';
    }
    const dcTemplate = fs.readFileSync('templates/docker-compose.yml.template', 'utf-8');
    const yml = util.template(
        dcTemplate,
        { 
            MYSQL_ROOT_PASSWORD: NC_CONFIG['MYSQL_ROOT_PASSWORD'],
            MYSQL_DATABASE: NC_CONFIG['MYSQL_DATABASE'],
            MYSQL_PASSWORD: NC_CONFIG['MYSQL_PASSWORD'],
            MYSQL_USER: NC_CONFIG['MYSQL_USER'],
            PORT: NC_CONFIG['PORT'],
            IMAGE_OR_BUILD: IMAGE_OR_BUILD
        }
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
