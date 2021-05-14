'use strict'

module.exports = {
    update
};

const util = require('./utility');
const fs = require('fs-extra');
const jsyml = require('js-yaml');
const path = require('path');

const CONFIG = util.loadConfig();
const PARAMETERS = CONFIG['CONFIG_YML_DEFAULT_PARAMETERS'];
const DATA_DIR = CONFIG['DATA_DIR'];
const DOCKER_DIR = `${DATA_DIR}/${CONFIG['DOCKER_DIR_RELATIVE_PATH']}`;
const CONFIG_YML_PATH = `${DATA_DIR}/config.yml`;

const INDENTATION_WIDTH = 2;

// public
function update() {
    if (!fs.existsSync(CONFIG_YML_PATH)) {
        createDefaultConfigYml();
    } else {
        tidyConfigYml();
    }

    createDockerComposeYml();
}

// private
function createDefaultConfigYml() {
    const defaultConfigYmlAsObject = getDefaultConfigYMLAsObject();
    const defaultConfigYmlAsString = jsyml.dump(
        defaultConfigYmlAsObject,
        {
            'indent': INDENTATION_WIDTH,
            'lineWidth': -1
        }
    );

    const defaultConfigYmlAsStringWithDesc = insertDescsToConfig(defaultConfigYmlAsString);
    fs.writeFileSync(CONFIG_YML_PATH, defaultConfigYmlAsStringWithDesc, 'utf8');
}

function getDefaultConfigYMLAsObject() {
    return getDefaultConfigYMLAsObjectRecursively(PARAMETERS);
}

/**
 * getDefaultConfigYMLAsObject.
 *
 * @param {object|null} parameters
 * @return {object|null}
 */
function getDefaultConfigYMLAsObjectRecursively(parameters) {
    if (!parameters) {
        return null;
    }

    let result = {};
    for (const [key, value] of Object.entries(parameters)) {
        validatePrameterValue(value);

        if (value.hasOwnProperty('DEFAULT_VALUE')) {
            result[key] = value['DEFAULT_VALUE'];
        }

        if (value.hasOwnProperty('CHILDREN')) {
            result[key] = getDefaultConfigYMLAsObjectRecursively(value['CHILDREN']);
        }
    }
    return result;
}

/**
 * validatePrameter.
 *
 * @param {Object} value
 */
function validatePrameterValue(value) {
    if (value.hasOwnProperty('DEFAULT_VALUE') && value.hasOwnProperty('CHILDREN')) {
        throw new Error('DEFAULT_VALUE and CHILDREN must not be set together.');
    }
}

/**
 * insertDesc.
 *
 * @param {string} ymlString
 */
function insertDescsToConfig(ymlString) {
    class CurrentItem {
        /**
         * family chain (in most cases(an exceptional example is written below), keys of the item and its parent and further its parent...) of the items in config.yml
         * but e.g. 
         * MACADDRESS: |
         *   AA:BB:CC:DD:EE:FF is the mac address
         *   of that device.
         * AA in the above item can be a currentItem, but this is not a key name
         * this currentItem should be ignored.
         * @param {Array<string>} chain - family chain, the smaller the array index, the nearer to the root the item.
         */
        constructor(chain) {
            this.chain = chain;
        }

        get depth() {
            return this.chain.length - 1;
        }
    }

    /**
     * updateCurrentItem.
     *
     * @param {CurrentItem} currentItem
     * @param {string} key
     * @param {number} depth
     */
    function updateCurrentItem(currentItem, key, depth) {
        if (currentItem.depth == depth) {
            currentItem.chain.pop();
            currentItem.chain.push(key);
        } else if (currentItem.depth < depth) {
            currentItem.chain.push(key);
        } else  {
            const delta = currentItem.depth - depth;
            for (let i = 0; i < delta + 1; ++i) {
                currentItem.chain.pop();
            }
            currentItem.chain.push(key);
        }
    }

    /**
     * getTargetParam.
     *
     * @param {CurrentItem} currentItem
     * @return {object|null}
     */
    function getTargetParam(currentItem) {
        let targetParam = PARAMETERS;
        const chain = currentItem.chain;
        for (let i = 0, length = chain.length; i < length; ++i) {
            targetParam = targetParam[chain[i]];
            // if not last element
            if (i !== length - 1) {
                // e.g. 
                // MACADDRESS: |
                //   AA:BB:CC:DD:EE:FF is the mac address
                //   of that device.
                // AA in the above item can be a currentItem, but this is not a key name.
                // this currentItem should be ignored.
                targetParam = targetParam['CHILDREN'];
                if (!targetParam) {
                    return null;
                }
            }
        }
        return targetParam;
    }

    let result = 
`############################
#### CONFIGURATION FILE ####
############################`;

    const lines = ymlString.split('\n');

    let currentItem = new CurrentItem([]);
    for (const line of lines) {
        //////////////////////($1-)(-----------------$2---------------------------)//
        const REG_PATTERN = /^(\s*)(\w[\w!"#$%&'()\*\+\-\.,\/;<=>?@\[\\\]^_`{|}~]*):/;
        const match = line.match(REG_PATTERN);
        if (match) {
            const spaces = match[1];
            const key = match[2];
            const depth = spaces.length / INDENTATION_WIDTH;
            updateCurrentItem(currentItem, key, depth);

            const targetParam = getTargetParam(currentItem);
            if (targetParam) {
                result = concatenateLine(result, '', 0);
                if (targetParam.hasOwnProperty('DESC')) {
                    const descLines = targetParam['DESC'].split('\n');
                    for (const descLine of descLines) {
                        if (descLine.length === 0) {
                            continue;
                        }
                        result = concatenateLine(result, '# ' + descLine, currentItem.depth * INDENTATION_WIDTH);
                    }
                }
            }
        }
        result = concatenateLine(result, line, 0)
    }
    return result;
}

function concatenateLine(srcStr, line, numberOfSpaces) {
    let spaces = '';
    for (let i = 0; i < numberOfSpaces; ++i) {
        spaces += ' ';
    }

    return srcStr + '\n' + spaces + line;
}

function tidyConfigYml() {
    const configYml = util.loadYml(CONFIG_YML_PATH);
    const defaultYml = getDefaultConfigYMLAsObject();
    checkDifferences(configYml, defaultYml);

    const newConfigYml = getAbsorbedConfig(configYml, defaultYml);

    const newConfigYmlAsString = jsyml.dump(
        newConfigYml,
        {
            'indent': INDENTATION_WIDTH,
            'lineWidth': -1
        }
    );

    const newConfigYmlAsStringWithDesc = insertDescsToConfig(newConfigYmlAsString);
    fs.writeFileSync(CONFIG_YML_PATH, newConfigYmlAsStringWithDesc, 'utf8');
}

function getAbsorbedConfig(currentConfig, defaultConfig) {
    let result = {};
    for (const key of Object.keys(defaultConfig)) {
        if (currentConfig.hasOwnProperty(key)) {
            if (key === 'CONFIG_PHP' || util.classOf(defaultConfig[key]) !== 'Object') {
                result[key] = currentConfig[key];
            } else {
                result[key] = getAbsorbedConfig(currentConfig[key], defaultConfig[key]);
            }
        } else {
            result[key] = defaultConfig[key];
        }
    }
    return result;
}

function checkDifferences(currentConfig, defaultConfig) {

    for (const key of Object.keys(currentConfig)) {
        if (key === 'CONFIG_PHP') {
            continue;
        }
        if (!defaultConfig.hasOwnProperty(key)) {
            throw new Error(`${key} in config.yml is an invalid config item.`);
        }
        const currentValue = currentConfig[key];
        const defaultValue = defaultConfig[key];
        const currentClass = util.classOf(currentValue);
        const defaultClass = util.classOf(defaultValue);

        if (currentClass !== defaultClass) {
            throw new Error(`The value of ${key} in config.yml is invalid.`);
        }
        if (currentClass === 'Object') {
            checkDifferences(currentValue, defaultValue);
        }
    }
}

function createDockerComposeYml() {
    const NC_CONFIG = util.loadYml(CONFIG_YML_PATH);
    const PROXY_DOCKER_FILE_RELATIVE_PATH = CONFIG['PROXY_DOCKER_FILE_RELATIVE_PATH'];

    const replacementWords = {
        IMAGE_OR_BUILD: getImageOrBuild(),
    };

    const SSL_CONFIG = NC_CONFIG['SSL'];

    if (SSL_CONFIG['ENABLE']) {
        replacementWords['ENVIRONMENT_VIRTUAL_HOST'] =
            `- VIRTUAL_HOST=${SSL_CONFIG['VIRTUAL_HOST']}`;
        replacementWords['NETWORKS_PROXY'] = '- proxy-tier';
        replacementWords['SERVICE_PROXY'] =
`proxy:
    build:
      context: ${path.dirname(PROXY_DOCKER_FILE_RELATIVE_PATH)}
      dockerfile: ${path.basename(PROXY_DOCKER_FILE_RELATIVE_PATH)}
    restart: always
    ports:
      - ${NC_CONFIG['PORT']}:80
      - ${SSL_CONFIG['PORT']}:443
    volumes:
      - /var/run/docker.sock:/tmp/docker.sock:ro
      - ../${CONFIG['CERTS_DIR_RELATIVE_PATH']}:/etc/nginx/certs
    networks:
      - proxy-tier`;

        replacementWords['NETWORKS'] = 
`networks:
  proxy-tier:`;
    } else {
        replacementWords['PORTS'] =
`ports:
      - ${NC_CONFIG['PORT']}:80`;
    }

    if (NC_CONFIG['REDIS']) {
        replacementWords['DEPENDS_ON_REDIS'] = '- redis';
        replacementWords['ENVIRONMENT_REDIS_HOST'] = '- REDIS_HOST=redis';
        replacementWords['SERVICE_REDIS'] =
`redis:
    image: redis:alpine
    restart: always`;
    }

    const dcTemplate = fs.readFileSync('files/docker-compose.yml.template', 'utf-8');
    const yml = util.template(
        dcTemplate,
        replacementWords
    );

    fs.mkdirsSync(`${DATA_DIR}/${CONFIG['CERTS_DIR_RELATIVE_PATH']}`);
    fs.mkdirsSync(DOCKER_DIR);
    fs.writeFileSync(`${DOCKER_DIR}/docker-compose.yml`, yml, 'utf8');
}

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
