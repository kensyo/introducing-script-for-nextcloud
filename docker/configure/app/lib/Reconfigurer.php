<?php

require_once 'lib/ConfigurerBase.php';

class Reconfigurer extends ConfigurerBase {
    protected const EXTERNAL_FILE_PATH = '/tmp/info.txt';

    private string $key;
    private string $newValue;
    private string $keyToConvey;

    public function __construct(string $key, string $newValue, string $keyToConvey = "") {
        require parent::CONFIG_FILE_PATh;
        if (!array_key_exists($key, $CONFIG)) {
            throw new Exception("Non-existent key was specififed.");
        }
        if (strcmp($keyToConvey, "") != 0 && !array_key_exists($keyToConvey, $CONFIG)) {
            throw new Exception("Non-existent key was specififed.");
        }
        $this->key = $key;
        $this->newValue = $newValue;
        $this->keyToConvey = $keyToConvey;
    }

    public function execute() {
        if (strcmp($this->keyToConvey, "") != 0) {
            $this->writeConfigValue();
        }
        parent::execute();
    }

    protected function writeConfigValue() {
        require parent::CONFIG_FILE_PATh;
        file_put_contents(self::EXTERNAL_FILE_PATH, $CONFIG[$this->keyToConvey]);
    }

    protected function createContent() {
        require parent::CONFIG_FILE_PATh;
        $CONFIG[$this->key] = $this->newValue;
        return $CONFIG;
    }

    protected function getOutputPath() {
        return parent::CONFIG_FILE_PATh;
    }
}
