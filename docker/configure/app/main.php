<?php

$con = factory($argv);
$con->execute();

function factory($args) {
    $operation = $args[1];
    switch ($operation) {
        case "configure":
            require_once 'lib/Configurer.php';
            return new Configurer();
            break;

        case "reconfigure":
            $key = $args[2];
            $newValue = $args[3];
            switch ($key) {
                case "dbpassword":
                    require_once 'lib/Reconfigurer.php';
                    return new Reconfigurer($key, $newValue, 'dbuser');
                default:
                    throw new Exception("Invalid key name specified.");
            }
            break;
        default:
            throw new Exception("Invalid operation specified.");
            break;
    }
}
