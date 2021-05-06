'use strict'

module.exports = {
    route
};

// public
function route(operation) {
    if (operation === 'install') {
        const installer = require('./installer');
        installer.install();
    } else if (operation === 'update') {
        const updater = require('./updater');
        updater.update();
    } else {
        throw 'An invalid operation is specified.';
    }
}

// private
