/*
  +----------------------------------------------------------------------+
  | PHP extension header for b1gZIP                                      |
  +----------------------------------------------------------------------+
*/

#ifndef PHP_B1GZIP_H
#define PHP_B1GZIP_H

extern zend_module_entry b1gzip_module_entry;
#define phpext_b1gzip_ptr &b1gzip_module_entry

#ifdef PHP_WIN32
#define PHP_B1GZIP_API __declspec(dllexport)
#else
#define PHP_B1GZIP_API
#endif

PHP_MINIT_FUNCTION(b1gzip);
PHP_MSHUTDOWN_FUNCTION(b1gzip);
PHP_RINIT_FUNCTION(b1gzip);
PHP_RSHUTDOWN_FUNCTION(b1gzip);
PHP_MINFO_FUNCTION(b1gzip);

PHP_FUNCTION(b1gzip_create);
PHP_FUNCTION(b1gzip_add);
PHP_FUNCTION(b1gzip_final);

#endif /* PHP_B1GZIP_H */
