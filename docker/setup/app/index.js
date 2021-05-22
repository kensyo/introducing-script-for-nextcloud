'use strict'

if (process.argv.length <= 2) {
    console.error('Specify an operation');
    process.exit(1);
}

const OPERATION = process.argv[2];

const router = require('./lib/router');
router.route(OPERATION);

// ./nextcloud install i.e. docker-compose run --rm app install ですることは
// sql 関連の設定をプロンプトで聞き出し、それを反映したdocker-compose file （最小構成）を作成し、実行する。
// 実行は60秒くらい待ってから(可能ならば curl で成功ステータスが帰ってくるのを確認してから)終了する。
//
// ./nextcloud reinstall i.e. docker-compose run --rm app install ですることは
// sql 関連のパスワードと
