PHP_ARG_WITH([b1gzip],
  [whether to enable b1gZIP support],
  [AS_HELP_STRING([--with-b1gzip[=DIR]], [Build b1gZIP; DIR is the extracted ZipArchive source directory])],
  [no])

if test "$PHP_B1GZIP" != "no"; then
  PHP_REQUIRE_CXX()

  if test "$PHP_B1GZIP" != "yes"; then
    if test ! -f "$PHP_B1GZIP/ZipArchive.h"; then
      AC_MSG_ERROR([ZipArchive.h was not found in $PHP_B1GZIP. Pass the extracted ZipArchive directory containing ZipArchive.h])
    fi
    PHP_ADD_INCLUDE([$PHP_B1GZIP])
  else
    AC_CHECK_HEADER([ZipArchive.h], [], [AC_MSG_ERROR([ZipArchive.h was not found on the include path; pass --with-b1gzip=DIR where DIR contains ZipArchive.h])])
  fi

  dnl The Artpol ZipArchive implementation classes (for example CZipArchive and
  dnl CZipMemFile) must be compiled together with this extension; the header alone
  dnl is not enough to satisfy the VTable and implementation symbols.
  ZIPARCHIVE_CPP_SOURCES=""
  for file in "$PHP_B1GZIP"/*.cpp; do
    if test -f "$file"; then
      ZIPARCHIVE_CPP_SOURCES="$ZIPARCHIVE_CPP_SOURCES $file"
    fi
  done

  PHP_ADD_LIBRARY([stdc++], [1], [B1GZIP_SHARED_LIBADD])
  PHP_SUBST([B1GZIP_SHARED_LIBADD])
  PHP_NEW_EXTENSION([b1gzip], [src/b1gzip.cpp $ZIPARCHIVE_CPP_SOURCES], [$ext_shared],, [-DZEND_ENABLE_STATIC_TSRMLS_CACHE=1])
fi
