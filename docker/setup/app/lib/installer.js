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

    const NEXTCLOUD_ADMIN_USER = rls.question(
        'Enter admin user name: ',
        {charlist: '$<a-z>$<A-Z>$<0-9>', min: 1, max: 16}
    );
    const NEXTCLOUD_ADMIN_PASSWORD = rls.questionNewPassword(
        'Enter admin user password: ',
        {charlist: '$<a-z>$<A-Z>$<0-9>!#%&()*+,-./;<=>?@[]^_{|}~', min: 1, max: 32}
    );
    const MYSQL_ROOT_PASSWORD = rls.questionNewPassword(
        'Enter MYSQL root password: ',
        {charlist: '$<a-z>$<A-Z>$<0-9>!#%&()*+,-./;<=>?@[]^_{|}~', min: 1, max: 32}
    );
    const MYSQL_DATABASE = rls.question(
        'Enter MYSQL database name: ',
        {charlist: '$<a-z>$<A-Z>$<0-9>', min: 1, max: 16}
    );
    const MYSQL_USER = rls.question(
        'Enter MYSQL user name: ',
        {charlist: '$<a-z>$<A-Z>$<0-9>', min: 1, max: 16}
    );
    const MYSQL_PASSWORD = rls.questionNewPassword(
        'Enter MYSQL user password: ',
        {charlist: '$<a-z>$<A-Z>$<0-9>!#%&()*+,-./;<=>?@[]^_{|}~', min: 1, max: 32}
    );

    const util = require('./utility');
    const base = util.loadYml('files/base-docker-compose.yml');

    base['services']['db']['environment'] = [
        `MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}`,
        `MYSQL_USER=${MYSQL_USER}`,
        `MYSQL_PASSWORD=${MYSQL_PASSWORD}`,
        `MYSQL_DATABASE=${MYSQL_DATABASE}`
    ];

    base['services']['app']['image'] = 'nextcloud';
    const environment = base['services']['app']['environment'];
    environment.push(`NEXTCLOUD_ADMIN_USER=${NEXTCLOUD_ADMIN_USER}`);
    environment.push(`NEXTCLOUD_ADMIN_PASSWORD=${NEXTCLOUD_ADMIN_PASSWORD}`);
    environment.push(`MYSQL_USER=${MYSQL_USER}`);
    environment.push(`MYSQL_PASSWORD=${MYSQL_PASSWORD}`);
    environment.push(`MYSQL_DATABASE=${MYSQL_DATABASE}`);

    const CONFIG = util.loadConfig();
    const DOCKER_DIR = CONFIG['DATA_DIR'] + '/' + CONFIG['DOCKER_DIR_RELATIVE_PATH'];
    const fs = require('fs-extra');
    const jsyml = require('js-yaml');
    fs.mkdirsSync(DOCKER_DIR);
    fs.writeFileSync(`${DOCKER_DIR}/docker-compose.yml`, jsyml.dump(base), 'utf8');
}
