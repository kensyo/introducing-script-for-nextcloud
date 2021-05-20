<?php

class Reconfigurer {
    private string $key;
    private string $newValue;

    private const CONFIG_FILE_PATh = '/ncdata/web/config/config.php';
    private const OUTPUT_FILE_PATH = '/tmp/info.txt';

    public function __construct(string $key, string $newValue) {
        $this->key = $key;
        $this->newValue = $newValue;
    }

    public function reconfigure() {
        require_once self::CONFIG_FILE_PATh;

        switch ($this->key) {
            case "dbpassword":
                file_put_contents(self::OUTPUT_FILE_PATH, $CONFIG['dbuser']);
                break;
        }

        $CONFIG[$this->key] = $this->newValue;
        file_put_contents(
            self::CONFIG_FILE_PATh,
            "<?php\n" . '$CONFIG = ' .var_export($CONFIG, true) . ';'
        );
    }
}
