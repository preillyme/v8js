--TEST--
Test V8Js::setModuleNormaliser : Forward exceptions
--SKIPIF--
<?php require_once(dirname(__FILE__) . '/skipif.inc'); ?>
--FILE--
<?php

$JS = <<< EOT
var foo = require("./test");
EOT;

$v8 = new V8Js();
$v8->setModuleNormaliser(function($module) {
    throw new Exception('some exception');
});
$v8->setModuleLoader(function($module) {
	echo 'dummy ...';
});

$v8->executeString($JS, 'module.js', V8Js::FLAG_PROPAGATE_PHP_EXCEPTIONS);
?>
===EOF===
--EXPECTF--
Fatal error: Uncaught Exception: some exception in %s%ecommonjs_exception_002.php:9
Stack trace:
#0 [internal function]: {closur%s}('', './test')
#1 %s%ecommonjs_exception_002.php(15): V8Js->executeString('var foo = requi...', 'module.js', 4)
#2 {main}

Next V8JsScriptException: module.js:1: Exception: some exception in %s%ecommonjs_exception_002.php:9
Stack trace:
#0 [internal function]: {closur%s}('', './test')
#1 %s%ecommonjs_exception_002.php(15): V8Js->executeString('var foo = requi...', 'module.js', 4)
#2 {main} in %s%ecommonjs_exception_002.php:15
Stack trace:
#0 %s%ecommonjs_exception_002.php(15): V8Js->executeString('var foo = requi...', 'module.js', 4)
#1 {main}
  thrown in %s%ecommonjs_exception_002.php on line 15
