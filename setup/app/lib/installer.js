'use strict'

module.exports = {
    install
};

// public
function install() {
    const util = require('./utility');
    const fs = require('fs');
    const CONFIG = util.loadConfig();
    const YML_DEFAULTS = CONFIG['CONFIG_YML_DEFAULT_VALUES'];

    const template = fs.readFileSync('templates/config.yml.template', 'utf-8');
    const yml = util.template(
        template,
        { 
            MYSQL_ROOT_PASSWORD: YML_DEFAULTS['MYSQL_ROOT_PASSWORD'],
            MYSQL_DATABASE: YML_DEFAULTS['MYSQL_DATABASE'],
            MYSQL_PASSWORD: YML_DEFAULTS['MYSQL_PASSWORD'],
            MYSQL_USER: YML_DEFAULTS['MYSQL_USER'],
            PORT: YML_DEFAULTS['PORT'],
            CUSTOM_DOCKER_FILE_PATH: YML_DEFAULTS['CUSTOM_DOCKER_FILE_RELATIVE_PATH'],
        }
    );

    const NC_CONFIG_PATH = `${CONFIG['DATA_DIR']}/config.yml`;

    fs.writeFileSync(NC_CONFIG_PATH, yml, 'utf8');
    
    const dcc = require('./dockerConfsCreater');
    dcc.createDockerComposeYml();

}
