PHP_ARG_WITH(v8js, for V8 Javascript Engine,
[  --with-v8js           Include V8 JavaScript Engine])

if test "$PHP_V8JS" != "no"; then
  SEARCH_PATH="/usr/local /usr"

  for libname in v8 node; do
    SEARCH_FOR="lib$libname.$SHLIB_SUFFIX_NAME"

    if test -d "$PHP_V8JS"; then
      SEARCH_PATH="$PHP_V8JS"

      # set rpath, so library loader picks up libv8 even if it's not on the
      # system's library search path
      case $host_os in
        darwin* )
          # MacOS does not support --rpath
          ;;
        * )
          LDFLAGS="$LDFLAGS -Wl,--rpath=$PHP_V8JS/$PHP_LIBDIR"
          ;;
      esac
    fi

    AC_MSG_CHECKING([for V8 files in default path])
    ARCH=$(uname -m)

    for i in $SEARCH_PATH ; do
      if test -r "$i/$PHP_LIBDIR/$SEARCH_FOR" -a -r "$i/include/$libname/v8.h"; then
        V8_INCLUDE_DIR="$i/include/$libname"
        V8_LIBRARY_DIR="$i/$PHP_LIBDIR"
        AC_MSG_RESULT(found in $i)
        break 2
      fi

      # Debian installations
      if test -r "$i/$PHP_LIBDIR/$ARCH-linux-gnu/$SEARCH_FOR"; then
        V8_INCLUDE_DIR="$i/include/$libname"
        V8_LIBRARY_DIR="$i/$PHP_LIBDIR/$ARCH-linux-gnu"
        AC_MSG_RESULT(found in $i)
        break 2
      fi

      # Manual installations
      if test -r "$i/$PHP_LIBDIR/$SEARCH_FOR" -a -r "$i/include/libplatform/libplatform.h"; then
        V8_INCLUDE_DIR="$i/include"
        V8_LIBRARY_DIR="$i/$PHP_LIBDIR"
        AC_MSG_RESULT(found in $i)
        break 2
      fi
    done
  done

  AC_DEFINE_UNQUOTED([PHP_V8_EXEC_PATH], "$V8_LIBRARY_DIR/$SEARCH_FOR", [Full path to libv8 library file])

  if test -z "$V8_INCLUDE_DIR" || test -z "$V8_LIBRARY_DIR"; then
    AC_MSG_RESULT([not found])
    AC_MSG_ERROR([Please reinstall the v8 distribution])
  fi

  PHP_ADD_INCLUDE($V8_INCLUDE_DIR)
  PHP_ADD_LIBRARY_WITH_PATH($libname, $V8_LIBRARY_DIR, V8JS_SHARED_LIBADD)
  PHP_SUBST(V8JS_SHARED_LIBADD)

  PHP_REQUIRE_CXX()


  AC_CACHE_CHECK(for C standard version, ac_cv_v8_cstd, [
    ac_cv_v8_cstd="c++20"
    old_CPPFLAGS=$CPPFLAGS
    AC_LANG_PUSH([C++])
    CPPFLAGS="-std="$ac_cv_v8_cstd
    AC_RUN_IFELSE([AC_LANG_SOURCE([[int main() { return 0; }]])],[],[
      ac_cv_v8_cstd="c++17"
      CPPFLAGS="-std="$ac_cv_v8_cstd
      AC_RUN_IFELSE([AC_LANG_SOURCE([[int main() { return 0; }]])],[],[ ac_cv_v8_cstd="c++14" ],[])
    ],[])
    AC_LANG_POP([C++])
    CPPFLAGS=$old_CPPFLAGS
  ]);

  AC_CACHE_CHECK(how to allow c++14 narrowing, ac_cv_v8_narrowing, [
    ac_cv_v8_narrowing=""
    old_CXXFLAGS=$CXXFLAGS
    AC_LANG_PUSH([C++])
    CXXFLAGS="-std="$ac_cv_v8_cstd
    AC_RUN_IFELSE([AC_LANG_SOURCE([[int main() {
        struct { unsigned int x; } foo = {-1};
        (void) foo;
        return 0;
    }]])],[ac_cv_v8_narrowing=""],[
        CXXFLAGS="-Wno-c++14-narrowing -std="$ac_cv_v8_cstd
        AC_RUN_IFELSE([AC_LANG_SOURCE([[int main() {
            struct { unsigned int x; } foo = {-1};
            (void) foo;
            return 0;
        }]])],[ac_cv_v8_narrowing="-Wno-c++14-narrowing"],[
            CXXFLAGS="-Wno-narrowing -std="$ac_cv_v8_cstd
            AC_RUN_IFELSE([AC_LANG_SOURCE([[int main() {
                struct { unsigned int x; } foo = {-1};
                (void) foo;
                return 0;
            }]])],[ac_cv_v8_narrowing="-Wno-narrowing"],[
                AC_MSG_ERROR([cannot compile with narrowing])
            ],[])
        ],[])
    ],[])
    AC_LANG_POP([C++])
    CXXFLAGS=$old_CXXFLAGS
  ]);


  old_LIBS=$LIBS
  old_LDFLAGS=$LDFLAGS
  old_CPPFLAGS=$CPPFLAGS

  AC_LANG_PUSH([C++])

  CPPFLAGS="$CPPFLAGS -I$V8_INCLUDE_DIR -std=$ac_cv_v8_cstd"
  LDFLAGS="$LDFLAGS -L$V8_LIBRARY_DIR"

  if test "$libname" = "v8"; then
    AC_MSG_CHECKING([for libv8_libplatform])
    AC_DEFUN([V8_CHECK_LINK], [
      save_LIBS="$LIBS"
      LIBS="$LIBS $1 -lv8_libplatform -lv8"
      AC_LINK_IFELSE([AC_LANG_PROGRAM([
        #include <libplatform/libplatform.h>
      ], [ v8::platform::NewDefaultPlatform(); ])], [
        dnl libv8_libplatform.so found
        AC_MSG_RESULT(found)
        V8JS_SHARED_LIBADD="$1 -lv8_libplatform $V8JS_SHARED_LIBADD"
          $3
      ], [ $4 ])
      LIBS="$save_LIBS"
    ])

    V8_CHECK_LINK([], [], [], [
      V8_CHECK_LINK([-lv8_libbase], [], [], [
        AC_MSG_ERROR([could not find libv8_libplatform library])
      ])
    ])
  fi


  dnl
  dnl Check for V8 version
  dnl (basic support for library linking assumed to be achieved above)
  dnl
  LIBS="$LIBS $V8JS_SHARED_LIBADD"
  AC_CACHE_CHECK(for V8 version, ac_cv_v8_version, [
AC_RUN_IFELSE([AC_LANG_SOURCE([[#include <v8.h>
#include <iostream>
#include <fstream>
using namespace std;

int main ()
{
	ofstream testfile ("conftestval");
	if (testfile.is_open()) {
		testfile << v8::V8::GetVersion();
		testfile << "\n";
		testfile.close();
		return 0;
	}
	return 1;
}]])],[ac_cv_v8_version=`cat ./conftestval|awk '{print $1}'`],[ac_cv_v8_version=NONE],[ac_cv_v8_version=NONE])
])

  if test "$ac_cv_v8_version" != "NONE"; then
    ac_IFS=$IFS
    IFS=.
    set $ac_cv_v8_version
    IFS=$ac_IFS
    V8_API_VERSION=`expr [$]1 \* 1000000 + [$]2 \* 1000 + [$]3`
    if test "$V8_API_VERSION" -lt 9000000 ; then
       AC_MSG_ERROR([libv8 must be version 9.0 or greater])
    fi
    AC_DEFINE_UNQUOTED([PHP_V8_API_VERSION], $V8_API_VERSION, [ ])
    AC_DEFINE_UNQUOTED([PHP_V8_VERSION], "$ac_cv_v8_version", [ ])
  else
    AC_MSG_ERROR([could not determine libv8 version])
  fi


  dnl
  dnl  Scan for blob.bin files (that might be needed)
  dnl
  AC_DEFUN([V8_SEARCH_BLOB], [
	AC_MSG_CHECKING([for $1])
	blob_found=0

	for i in "$V8_LIBRARY_DIR" "$V8_INCLUDE_DIR/../share/v8"; do
	  if test -r "$i/$1"; then
		AC_MSG_RESULT([found ($i/$1)])
		AC_DEFINE_UNQUOTED([$2], "$i/$1", [Full path to $1 file])
		blob_found=1
	  fi
	done

	if test "$blob_found" -ne 1; then
	  AC_MSG_RESULT([not found])
	fi
  ])
  V8_SEARCH_BLOB([natives_blob.bin], [PHP_V8_NATIVES_BLOB_PATH])
  V8_SEARCH_BLOB([snapshot_blob.bin], [PHP_V8_SNAPSHOT_BLOB_PATH])


  dnl
  dnl  Check for v8::V8::InitializeSandbox
  dnl
  AC_CACHE_CHECK([for v8::V8::InitializeSandbox], ac_cv_has_initialize_sandbox, [
    AC_LINK_IFELSE([AC_LANG_PROGRAM([
      #define V8_ENABLE_SANDBOX 1
      #include <v8.h>
    ], [ v8::V8::InitializeSandbox(); ])], [
      ac_cv_has_initialize_sandbox=yes
    ], [
      ac_cv_has_initialize_sandbox=no
    ])
  ])
  if test "x$ac_cv_has_initialize_sandbox" = "xyes"; then
    AC_DEFINE([V8_HAS_INITIALIZE_SANDBOX], [1],
              [Define if V8::InitializeSandbox must be called.])
  fi

  dnl
  dnl  Check for v8::ArrayBuffer::Allocator::NewDefaultAllocator
  dnl
  AC_CACHE_CHECK([for v8::ArrayBuffer::Allocator::NewDefaultAllocator], ac_cv_has_default_allocator, [
    AC_LINK_IFELSE([AC_LANG_PROGRAM([
      #include <v8.h>
    ], [ v8::ArrayBuffer::Allocator::NewDefaultAllocator(); ])], [
      ac_cv_has_default_allocator=yes
    ], [ 
      ac_cv_has_default_allocator=no
    ])
  ])
  if test "x$ac_cv_has_default_allocator" = "xno"; then
    AC_DEFINE([USE_INTERNAL_ALLOCATOR], [1],
              [Define unless v8::ArrayBuffer::Allocator::NewDefaultAllocator is usable.])
  fi

  AC_LANG_POP([C++])
  LIBS=$old_LIBS
  LDFLAGS="$old_LDFLAGS"
  CPPFLAGS=$old_CPPFLAGS

  AC_DEFINE([V8_DEPRECATION_WARNINGS], [1], [Enable compiler warnings when using V8_DEPRECATED apis.])

  PHP_ADD_INCLUDE($V8_INCLUDE_DIR)
  PHP_NEW_EXTENSION(v8js, [	\
    v8js_array_access.cc	\
    v8js_class.cc			\
    v8js_commonjs.cc		\
    v8js_convert.cc			\
    v8js_exceptions.cc		\
    v8js_generator_export.cc	\
    v8js_main.cc			\
    v8js_methods.cc			\
    v8js_object_export.cc	\
	v8js_timer.cc			\
	v8js_v8.cc				\
    v8js_v8object_class.cc	\
    v8js_variables.cc		\
  ], $ext_shared, , "$ac_cv_v8_narrowing -std="$ac_cv_v8_cstd)

  PHP_ADD_MAKEFILE_FRAGMENT
fi

dnl Local variables:
dnl tab-width: 4
dnl c-basic-offset: 4
dnl End:
dnl vim600: noet sw=4 ts=4 fdm=marker
dnl vim<600: noet sw=4 ts=4
