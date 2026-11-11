PHP_ARG_WITH([b1gzip],
  [whether to enable b1gZIP support],
  [AS_HELP_STRING([--with-b1gzip[=DIR]], [Build b1gZIP; DIR is the extracted ZipArchive source/library directory])],
  [no])

if test "$PHP_B1GZIP" != "no"; then
  PHP_REQUIRE_CXX()

  if test "$PHP_B1GZIP" != "yes"; then
    if test ! -f "$PHP_B1GZIP/ZipArchive.h"; then
      AC_MSG_ERROR([ZipArchive.h was not found in $PHP_B1GZIP. Pass the extracted ZipArchive directory containing ZipArchive.h])
    fi
    PHP_ADD_INCLUDE([$PHP_B1GZIP])
    PHP_ADD_LIBRARY_WITH_PATH([ziparch], [$PHP_B1GZIP], [B1GZIP_SHARED_LIBADD])
  else
    AC_CHECK_HEADER([ZipArchive.h], [], [AC_MSG_ERROR([ZipArchive.h was not found on the include path; pass --with-b1gzip=DIR where DIR contains ZipArchive.h])])
    PHP_ADD_LIBRARY([ziparch], [1], [B1GZIP_SHARED_LIBADD])
  fi

  PHP_SUBST([B1GZIP_SHARED_LIBADD])
  PHP_NEW_EXTENSION([b1gzip], [src/b1gzip.cpp], [$ext_shared],, [-DZEND_ENABLE_STATIC_TSRMLS_CACHE=1])
fi
