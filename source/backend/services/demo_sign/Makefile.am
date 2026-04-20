SUBDIRS =

AM_CFLAGS = -std=c11 -O2 -Wall -Wextra -Wpedantic

prglibdir = $(prefix)/services/demo_sign
prglib_LTLIBRARIES = libdemo_sign.la
prglib_DATA = services.xml

EXTRA_DIST = services.xml demo_sign_svc.h
noinst_HEADERS = demo_sign_svc.h

libdemo_sign_la_SOURCES = demo_sign_skeleton.c demo_sign_svc.c $(top_srcdir)/source/backend/src/demosign.c
libdemo_sign_la_CPPFLAGS = -I$(top_srcdir)/source/backend/include $(AXIS2C_CPPFLAGS)

repodir = $(top_builddir)/axis2_repo/services/demo_sign

all-local: libdemo_sign.la
	@$(MKDIR_P) '$(top_builddir)/axis2_repo'
	cp -f '$(top_srcdir)/source/backend/axis2_repo/axis2.xml' '$(top_builddir)/axis2_repo/axis2.xml'
	@$(MKDIR_P) '$(repodir)'
	cp -f '$(srcdir)/services.xml' '$(repodir)/services.xml'
	cp -f '.libs/libdemo_sign.so' '$(repodir)/libdemo_sign.so'

clean-local:
	rm -f '$(repodir)/libdemo_sign.so' '$(repodir)/services.xml'
