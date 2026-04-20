AC_PREREQ([2.69])
AC_INIT([demo-sign-server],[0.1.0],[example@example.invalid])
AM_INIT_AUTOMAKE([-Wall -Werror foreign subdir-objects])
AC_CONFIG_SRCDIR([source/backend/services/demo_sign/demo_sign_skeleton.c])
AC_CONFIG_HEADERS([config.h])

AC_PROG_CC
AM_PROG_AR
AC_PROG_INSTALL
LT_INIT

AC_ARG_WITH([axis2c],
  [AS_HELP_STRING([--with-axis2c=PREFIX],
    [Apache Axis2/C installation prefix (headers in PREFIX/include, libs in PREFIX/lib)])],
  [axis2c_prefix=$withval],
  [axis2c_prefix=${AXIS2C_HOME}])

AS_IF([test "x$axis2c_prefix" = x],
  [axis2c_prefix=/usr/local/axis2c])

AC_CACHE_CHECK([for Axis2/C include directory], [ax_cv_axis2c_include],
[ax_cv_axis2c_include=''
if test -f "${axis2c_prefix}/include/axis2_http_server.h"; then
  ax_cv_axis2c_include="${axis2c_prefix}/include"
else
  for ax_d in "${axis2c_prefix}"/include/axis2-*; do
    if test -f "$ax_d/axis2_http_server.h"; then
      ax_cv_axis2c_include=$ax_d
      break
    fi
  done
fi])
AS_IF([test "x$ax_cv_axis2c_include" = x],
  [AC_MSG_ERROR([Axis2/C headers not found under ${axis2c_prefix}/include (expected axis2_http_server.h)])])
AXIS2C_CPPFLAGS="-I${ax_cv_axis2c_include}"
AXIS2C_LDFLAGS="-L${axis2c_prefix}/lib"

AC_ARG_VAR([AXIS2C_LIBS], [Override Axis2/C libraries for linking (advanced)])

dnl Default matches Apache Axis2/C 1.6.x layout (simple HTTP server). For newer axis-axis2-c-core installs, set AXIS2C_LIBS when running configure.
AS_IF([test "x$AXIS2C_LIBS" = x],
  [AXIS2C_LIBS='-laxis2_http_receiver -laxis2_http_sender -laxis2_http_common -laxis2_engine -lneethi -laxis2_axiom -laxis2_parser -laxutil -lguththila -lpthread -ldl'])
dnl Add e.g. -lxml2 -lz when linking fails and libxml2-dev/zlib1g-dev are installed.

save_CPPFLAGS=$CPPFLAGS
save_LDFLAGS=$LDFLAGS
save_LIBS=$LIBS
CPPFLAGS="$CPPFLAGS $AXIS2C_CPPFLAGS"
LDFLAGS="$LDFLAGS $AXIS2C_LDFLAGS"
LIBS="$AXIS2C_LIBS $LIBS"

AC_MSG_CHECKING([whether we can link against Axis2/C])
AC_LINK_IFELSE(
  [AC_LANG_PROGRAM([[
#include <axis2_http_server.h>
#include <axutil_version.h>
  ]], [[
    const axis2_char_t *v = axis2_version_string();
    (void)axis2_http_server_create;
    return v ? 0 : 1;
  ]])],
  [AC_MSG_RESULT([yes])],
  [AC_MSG_RESULT([no])
   AC_MSG_ERROR([Axis2/C link check failed. Adjust --with-axis2c or set AXIS2C_LIBS to your installation's libraries.])])

CPPFLAGS=$save_CPPFLAGS
LDFLAGS=$save_LDFLAGS
LIBS=$save_LIBS

AC_SUBST([AXIS2C_CPPFLAGS])
AC_SUBST([AXIS2C_LDFLAGS])
AC_SUBST([AXIS2C_LIBS])

AC_CONFIG_FILES([
 Makefile
 source/backend/include/Makefile
 source/backend/services/Makefile
 source/backend/services/demo_sign/Makefile
 source/backend/src/Makefile
])
AC_OUTPUT
