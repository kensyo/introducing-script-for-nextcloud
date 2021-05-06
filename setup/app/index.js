'use strict'

if (process.argv.length <= 2) {
    console.error('Specify an operation');
    process.exit(1);
}

const OPERATION = process.argv[2];

const router = require('./lib/router');
router.route(OPERATION);

// 0. /app/config/config.yml ファイルを読み込む。
// 1. install か update なのかを operation で判別
// 2. install なら /ncdata/config.yml を作成する。update なら /ncdata/config.yml があるか確認し、ないなら終了する。
//   2.1. まず install なら templates/config.yml.template をテキストとして読み取る。
//   2.2. %%{}%% をデフォルト値で置換する。
//   2.3. /ncdata/config.yml に出力。
//   2.4 update なら確認して終了するだけ。
// 3. install update 共通で、/ncdata/ncdocker/app/Dockerfile 及び /ncdata/ncdocker/docker-compose.yml を作成する
//   3.1. config.yml に CUSTOM_DOCKER_FILE_PATH があり、かつ、そこに指定されたファイルがあるならば、それを元にビルドする docker-compose.yml を作成する。そうでないなら nextcloud イメージを用いる docker-compose.yml を作成する。なお、docker-compose.yml は ncdata/ncdocker に作成し、%%{}%%に config.yml に基づいて置換を施す。
//


