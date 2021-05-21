<?php

require_once 'lib/ConfigurerBase.php';

class Configurer extends ConfigurerBase {
    private const ADDITIONAL_CONFIG_FILE_PATH = '/ncdata/web/config/additional.config.php';

    protected function createContent() {
        require_once 'lib/spyc/Spyc.php';
        require parent::CONFIG_FILE_PATh;

        $NC_CONFIG = spyc_load_file('/ncdata/config.yml');
        $ADDITIONAL_CONFIG = $NC_CONFIG['CONFIG_PHP'];

        return $ADDITIONAL_CONFIG;
    }

    protected function getOutputPath() {
        return self::ADDITIONAL_CONFIG_FILE_PATH;
    }
}
