'use strict'

if (process.argv.length <= 2) {
    console.error('Specify an operation');
    process.exit(1);
}

const OPERATION = process.argv[2];

const router = require('./lib/router');
router.route(OPERATION);
