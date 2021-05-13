'use strict'

module.exports = {
    install
};

// public
function install() {
    createDockerComposeYmlForInstallation();

    // const template = fs.readFileSync('files/config.yml.template', 'utf-8');
    // const yml = util.template(
    //     template,
    //     YML_DEFAULTS
    // );

    // const NC_CONFIG_PATH = `${CONFIG['DATA_DIR']}/config.yml`;

    // fs.writeFileSync(NC_CONFIG_PATH, yml, 'utf8');

    // const dcc = require('./dockerConfsCreater');
    // dcc.createDockerComposeYml();

}

// private
function createDockerComposeYmlForInstallation() {
    const rls = require('readline-sync');

    console.info('Start setting.');

    const replacementWords = {};
    replacementWords['NEXTCLOUD_ADMIN_USER'] = rls.question(
        'Enter admin user name: ',
        {charlist: '$<a-z>$<A-Z>$<0-9>', min: 1, max: 16}
    );
    replacementWords['NEXTCLOUD_ADMIN_PASSWORD'] = rls.questionNewPassword(
        'Enter admin user password: ',
        {charlist: '$<a-z>$<A-Z>$<0-9>!#%&()*+,-./;<=>?@[]^_{|}~', min: 1, max: 32}
    );
    replacementWords['MYSQL_ROOT_PASSWORD'] = rls.questionNewPassword(
        'Enter MYSQL root password: ',
        {charlist: '$<a-z>$<A-Z>$<0-9>!#%&()*+,-./;<=>?@[]^_{|}~', min: 1, max: 32}
    );
    replacementWords['MYSQL_DATABASE'] = rls.question(
        'Enter MYSQL database name: ',
        {charlist: '$<a-z>$<A-Z>$<0-9>', min: 1, max: 16}
    );
    replacementWords['MYSQL_USER'] = rls.question(
        'Enter MYSQL user name: ',
        {charlist: '$<a-z>$<A-Z>$<0-9>', min: 1, max: 16}
    );
    replacementWords['MYSQL_PASSWORD'] = rls.questionNewPassword(
        'Enter MYSQL user password: ',
        {charlist: '$<a-z>$<A-Z>$<0-9>!#%&()*+,-./;<=>?@[]^_{|}~', min: 1, max: 32}
    );

    const fs = require('fs-extra');
    const template = fs.readFileSync(
        'files/installaion-docker-compose.yml.template',
        'utf-8'
    );
    const util = require('./utility');
    const ymlText = util.template(
        template,
        replacementWords
    );

    const CONFIG = util.loadConfig();
    const DOCKER_DIR = CONFIG['DATA_DIR'] + '/' + CONFIG['DOCKER_DIR_RELATIVE_PATH'];
    fs.mkdirsSync(DOCKER_DIR);
    fs.writeFileSync(DOCKER_DIR + '/docker-compose.yml', ymlText, 'utf8');
}
