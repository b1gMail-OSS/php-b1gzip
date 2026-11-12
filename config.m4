PHP_ARG_WITH([b1gzip],
  [whether to enable b1gZIP support],
  [AS_HELP_STRING([--with-b1gzip[=DIR]], [Build b1gZIP and automatically build Artpol ZipArchive; optionally use an existing ZipArchive source directory])],
  [no])

if test "$PHP_B1GZIP" != "no"; then
  PHP_REQUIRE_CXX()

  ZIPARCHIVE_WORK_DIR="$srcdir/.deps/b1gzip-ziparchive"
  ZIPARCHIVE_SOURCE_ARG=""
  if test "$PHP_B1GZIP" != "yes"; then
    ZIPARCHIVE_SOURCE_ARG="--source-dir=$PHP_B1GZIP"
  fi

  AC_MSG_NOTICE([Building Artpol ZipArchive dependency with CMake])
  if ! sh "$srcdir/build-ziparchive.sh" --work-dir="$ZIPARCHIVE_WORK_DIR" $ZIPARCHIVE_SOURCE_ARG; then
    AC_MSG_ERROR([Unable to build Artpol ZipArchive. See the CMake output above])
  fi

  ZIPARCHIVE_INCLUDE_DIR=`cat "$ZIPARCHIVE_WORK_DIR/include-dir.txt"`
  ZIPARCHIVE_LIBRARY_DIR=`cat "$ZIPARCHIVE_WORK_DIR/library-dir.txt"`

  PHP_ADD_INCLUDE([$ZIPARCHIVE_INCLUDE_DIR])
  PHP_ADD_LIBRARY_WITH_PATH([ZipArchive], [$ZIPARCHIVE_LIBRARY_DIR], [B1GZIP_SHARED_LIBADD])
  PHP_ADD_LIBRARY([stdc++], [1], [B1GZIP_SHARED_LIBADD])
  PHP_SUBST([B1GZIP_SHARED_LIBADD])
  PHP_NEW_EXTENSION([b1gzip], [src/b1gzip.cpp], [$ext_shared],, [-DZEND_ENABLE_STATIC_TSRMLS_CACHE=1])
fi
