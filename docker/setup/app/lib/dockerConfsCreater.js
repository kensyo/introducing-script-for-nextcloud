'use strict'

module.exports = {
    createDockerComposeYml,
};

const fs = require('fs-extra');
const path = require('path');
const util = require('./utility');

const CONFIG = util.loadConfig();
const DATA_DIR = CONFIG['DATA_DIR'];
const DOCKER_DIR = `${DATA_DIR}/${CONFIG['DOCKER_DIR_RELATIVE_PATH']}`;
const NC_CONFIG = util.loadYml(`${DATA_DIR}/config.yml`); // TODO: validation

// public
function createDockerComposeYml() {
    tidyConfig();

    const replacementWords = {
        MYSQL_ROOT_PASSWORD: NC_CONFIG['MYSQL_ROOT_PASSWORD'],
        MYSQL_DATABASE: NC_CONFIG['MYSQL_DATABASE'],
        MYSQL_PASSWORD: NC_CONFIG['MYSQL_PASSWORD'],
        MYSQL_USER: NC_CONFIG['MYSQL_USER'],
        PORT: NC_CONFIG['PORT'],
        IMAGE_OR_BUILD: getImageOrBuild(),
    };

    let templateToRead = null;
    const PROXY_DOCKER_FILE_RELATIVE_PATH = CONFIG['PROXY_DOCKER_FILE_RELATIVE_PATH'];
    if (NC_CONFIG['SSL']) {
        templateToRead = 'files/ssl-docker-compose.yml.template';
        replacementWords['VIRTUAL_HOST'] = NC_CONFIG['SSL_VIRTUAL_HOST'];
        replacementWords['SSL_PORT'] = NC_CONFIG['SSL_PORT'];
        replacementWords['CERTS_DIR'] = CONFIG['CERTS_DIR_RELATIVE_PATH'];
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

    fs.mkdirsSync(`${DATA_DIR}/${CONFIG['CERTS_DIR_RELATIVE_PATH']}`);
    fs.mkdirsSync(DOCKER_DIR);
    fs.writeFileSync(`${DOCKER_DIR}/docker-compose.yml`, yml, 'utf8');
}

// private
function getImageOrBuild() {
    const CUSTOM_DOCKER_FILE_RELATIVE_PATH = CONFIG['CUSTOM_DOCKER_FILE_RELATIVE_PATH'];

    if (fs.existsSync(`${DOCKER_DIR}/${CUSTOM_DOCKER_FILE_RELATIVE_PATH}`)) {
        return `build:
      context: ${path.dirname(CUSTOM_DOCKER_FILE_RELATIVE_PATH)}
      dockerfile: ${path.basename(CUSTOM_DOCKER_FILE_RELATIVE_PATH)}`;
    } else {
        return `# If you want to use a custom nextcloud docker image,
    # create ${CONFIG['CUSTOM_DOCKER_FILE_RELATIVE_PATH']} in the same directory as this file.
    # Then run ./nextcloud rebuild.
    image: nextcloud`;
    }
}

function tidyConfig() {
    const jsyml = require('js-yaml');

    const ncConfigTemplate = fs.readFileSync('files/config.yml.template', 'utf-8');
    const defaultNcConfigAsString = util.template(
        ncConfigTemplate,
        CONFIG['CONFIG_YML_DEFAULT_VALUES']
    );
    const defaultNcConfigAsObject = jsyml.load(defaultNcConfigAsString);
    checkDifferences(NC_CONFIG, defaultNcConfigAsObject);
    const newNcConfigAsObject = {...defaultNcConfigAsObject, ...NC_CONFIG};

    const newNcConfigAsText = util.template(
        ncConfigTemplate,
        newNcConfigAsObject
    );

    fs.writeFileSync(`${DATA_DIR}/config.yml`, newNcConfigAsText, 'utf8');

}

function checkDifferences(currentConfig, defaultConfig) {

    for (let key of Object.keys(currentConfig)) {
        if (!defaultConfig.hasOwnProperty(key)) {
            throw new Error(`${key} in config.yml is an invalid config item.`);
        }
        const currentConfigItemValue = currentConfig[key];
        const defaultConfigItemValue = defaultConfig[key];
        const currentConfigItemClass = util.classOf(currentConfigItemValue);
        const defaultConfigItemClass = util.classOf(defaultConfigItemValue);

        if (currentConfigItemClass !== defaultConfigItemClass) {
            throw new Error(`The value of ${key} in config.yml is invalid.`);
        }
        if (currentConfigItemClass === 'Object') {
            checkDifferences(currentConfigItemValue, defaultConfigItemValue);
        }
    }
}
