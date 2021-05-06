'use strict'

module.exports = {
    update
};

// public
function update() {
    const dcc = require('./dockerConfsCreater');
    dcc.createDockerComposeYml();
}

// private
