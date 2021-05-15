<?php

require_once 'lib/spyc/Spyc.php';

// $CONFIG is defined in config.php
require_once '/ncdata/web/config/config.php';

$ADDITIONAL_CONFIG_FILE_PATH = '/ncdata/web/config/additional.config.php';

$NC_CONFIG = spyc_load_file('/ncdata/config.yml');
$ADDITIONAL_CONFIG = $NC_CONFIG['CONFIG_PHP'];

file_put_contents(
    $ADDITIONAL_CONFIG_FILE_PATH,
    "<?php\n" . '$CONFIG = ' .var_export($ADDITIONAL_CONFIG, true) . ';'
);


/* file_put_contents('./hogehoge.txt', "<?php\n" . '$CONFIG = ' . var_export($CONFIG, true) . ';'); */

/* $SSL_CONFIG = $NC_CONFIG['SSL']; */
/* $VIRTUAL_HOST = $SSL_CONFIG['VIRTUAL_HOST']; */

/* if ($SSL_CONFIG['ENABLE']) { */
/*     if (!in_array($VIRTUAL_HOST, $CONFIG['trusted_domains'], true)) { */
/*         $CONFIG['trusted_domains'][] = $VIRTUAL_HOST; */
/*     } */
/* } else { */
/*     if (in_array($VIRTUAL_HOST, $CONFIG['trusted_domains'], true)) { */
/*         $index = array_search($VIRTUAL_HOST, $CONFIG['trusted_domains'], true); */
/*         unset($CONFIG['trusted_domains'][$index]); */
/*     } */
/* } */

/* var_export($data); */
/* var_export($CONFIG); */
