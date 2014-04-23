<?php
if (!defined('TYPO3_MODE')) {
	die ('Access denied.');
}
Tx_CunddComposer_Autoloader::register();
if (!class_exists('Cundd\\Rest\\Bootstrap')) {
	throw new RuntimeException('Could not find class \\Cundd\\Rest\\Bootstrap. '
		. 'Maybe the Composer dependencies have not been installed',
		1397921464
	);
}

$bootstrap = new \Cundd\Rest\Bootstrap;
$bootstrap->init();
$app = new \Cundd\Rest\Dispatcher;
$app->dispatch();
?>
