<?php

abstract class ConfigurerBase {
    protected const CONFIG_FILE_PATh = '/ncdata/web/config/config.php';

    public function execute() {
        $content = $this->createContent();
        $outputPath = $this->getOutputPath();

        $this->outputConfig($outputPath, $content);
    }

    abstract protected function createContent();
    abstract protected function getOutputPath();

    protected function outputConfig(string $outputPath, array $content) {
        file_put_contents(
            $outputPath,
            "<?php\n" . '$CONFIG = ' .var_export($content, true) . ';'
        );
    }
}
