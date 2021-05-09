'use strict'

module.exports = {
    install
};

// public
function install() {
    const util = require('./utility');
    const fs = require('fs-extra');
    const CONFIG = util.loadConfig();
    const YML_DEFAULTS = CONFIG['CONFIG_YML_DEFAULT_VALUES'];

    const template = fs.readFileSync('files/config.yml.template', 'utf-8');
    const yml = util.template(
        template,
        YML_DEFAULTS
    );

    const NC_CONFIG_PATH = `${CONFIG['DATA_DIR']}/config.yml`;

    fs.writeFileSync(NC_CONFIG_PATH, yml, 'utf8');
    
    const dcc = require('./dockerConfsCreater');
    dcc.createDockerComposeYml();

}
