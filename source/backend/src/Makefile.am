AM_CFLAGS = -std=c11 -O2 -Wall -Wextra -Wpedantic

bin_PROGRAMS = demo-sign-server
demo_sign_server_SOURCES = main.c demoposix.c
demo_sign_server_CPPFLAGS = -I$(top_srcdir)/source/backend/include $(AXIS2C_CPPFLAGS)
demo_sign_server_LDFLAGS = $(AXIS2C_LDFLAGS)
demo_sign_server_LDADD = $(AXIS2C_LIBS)
