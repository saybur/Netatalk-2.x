## Makefile for distrib/initscripts/

SUFFIXES = .tmpl .

pkgconfdir = @PKGCONFDIR@

#
# Template Generation
#

.tmpl:
	sed -e s@:BINDIR:@${bindir}@ \
	    -e s@:SBINDIR:@${sbindir}@ \
	    -e s@:ETCDIR:@${pkgconfdir}@ \
	    -e s@:PKGLIBEXECDIR:@${pkglibexecdir}@ \
	    -e s@:VERSION:@${VERSION}@ \
	    <$< >$@

GENERATED_FILES = \
	rc.a2boot.netbsd	\
	rc.afpd.netbsd		\
	rc.atalk.redhat-sysv	\
	rc.atalkd.netbsd	\
	rc.atalk.suse-sysv	\
	rc.cnid_metad.netbsd	\
	rc.papd.netbsd		\
	rc.timelord.netbsd	\
	rc.atalk.sysv		\
	rc.atalk.gentoo		\
	rc.atalk.debian		\
	a2boot.service		\
	afpd.service		\
	atalkd.service		\
	cnid.service		\
	papd.service		\
	timelord.service

TEMPLATES = \
	rc.a2boot.netbsd.tmpl		\
	rc.afpd.netbsd.tmpl		\
	rc.atalk.redhat-sysv.tmpl	\
	rc.atalkd.netbsd.tmpl		\
	rc.atalk.suse-sysv.tmpl		\
	rc.cnid_metad.netbsd.tmpl	\
	rc.papd.netbsd.tmpl		\
	rc.timelord.netbsd.tmpl		\
	rc.atalk.sysv.tmpl		\
	rc.atalk.gentoo.tmpl		\
	rc.atalk.debian.tmpl		\
	a2boot.service.tmpl		\
	afpd.service.tmpl		\
	atalkd.service.tmpl		\
	cnid.service.tmpl		\
	papd.service.tmpl		\
	timelord.service.tmpl

CLEANFILES = $(GENERATED_FILES) $(sysv_SCRIPTS) $(service_DATA) a2boot afpd atalkd cnid_metad papd timelord
EXTRA_DIST = $(TEMPLATES)

# overwrite automake uninstall
# not beautiful, but this way we can call the OS specific init script
# tools, like chkconfig, insserv or rc-update

uninstall: uninstall-startup

#
# checking for "redhat" style sysv scripts:
#

if USE_REDHAT_SYSV

sysvdir	= /etc/rc.d/init.d
sysv_SCRIPTS = netatalk

$(sysv_SCRIPTS): rc.atalk.redhat-sysv
	cp -f rc.atalk.redhat-sysv $(sysv_SCRIPTS)
	chmod a+x $(sysv_SCRIPTS)

install-data-hook:
	-chkconfig --add $(sysv_SCRIPTS)

uninstall-startup:
	-chkconfig --del $(sysv_SCRIPTS)
	rm -f $(DESTDIR)$(sysvdir)/$(sysv_SCRIPTS)

endif

#
# checking for general systemd scripts:
#

if USE_SYSTEMD

servicedir = /lib/systemd/system

service_DATA = a2boot.service afpd.service atalkd.service cnid.service papd.service timelord.service

install-data-hook:
	-systemctl daemon-reload
if SYSTEMD_START
	-systemctl enable $(service_DATA)
	-systemctl start $(service_DATA)
endif

uninstall-startup:
	-systemctl disable $(service_DATA)
	rm -f $(addprefix $(DESTDIR)$(servicedir)/, $(service_DATA))
	-systemctl daemon-reload

endif

#
# checking for "SuSE" style sysv scripts:
#

if USE_SUSE_SYSV

sysvdir	= /etc/init.d
sysv_SCRIPTS = netatalk

$(sysv_SCRIPTS): rc.atalk.suse-sysv
	cp -f rc.atalk.suse-sysv $(sysv_SCRIPTS)
	chmod a+x $(sysv_SCRIPTS)

install-data-hook:
	-insserv $(sysv_SCRIPTS)

uninstall-startup:
	-insserv -d $(sysv_SCRIPTS)
	rm -f $(DESTDIR)$(sysvdir)/$(sysv_SCRIPTS)

endif

#
# checking for NetBSD init scripts
#

if USE_NETBSD

sysvdir = /etc/rc.d
sysv_SCRIPTS = afpd atalkd cnid_metad papd timelord a2boot

afpd: rc.afpd.netbsd
	cp -f $? $@
	chmod a+x $@

atalkd: rc.atalkd.netbsd
	cp -f $? $@
	chmod a+x $@

cnid_metad: rc.cnid_metad.netbsd
	cp -f $? $@
	chmod a+x $@

papd: rc.papd.netbsd
	cp -f $? $@
	chmod a+x $@

timelord: rc.timelord.netbsd
	cp -f $? $@
	chmod a+x $@
	
a2boot: rc.a2boot.netbsd
	cp -f $< $@
	chmod a+x $@

install-data-hook:

uninstall-hook:

uninstall-startup: uninstall-am

endif

#
# checking for Solaris init scripts
#

if USE_SOLARIS

sysvdir = /etc/init.d
sysv_SCRIPTS = netatalk

$(sysv_SCRIPTS): rc.atalk.sysv
	cp -f rc.atalk.sysv $@
	chmod a+x $@

install-data-hook:
	rm -f $(DESTDIR)/etc/rc2.d/S90$(sysv_SCRIPTS)
	-ln -s ../init.d/$(sysv_SCRIPTS) $(DESTDIR)/etc/rc2.d/S90$(sysv_SCRIPTS)
	rm -f $(DESTDIR)/etc/rc0.d/K04$(sysv_SCRIPTS)
	-ln -s ../init.d/$(sysv_SCRIPTS) $(DESTDIR)/etc/rc0.d/K04$(sysv_SCRIPTS)

uninstall-startup:
	rm -f $(DESTDIR)$(sysvdir)/$(sysv_SCRIPTS) \
		$(DESTDIR)/etc/rc2.d/S90$(sysv_SCRIPTS) \
		$(DESTDIR)/etc/rc0.d/K04$(sysv_SCRIPTS)

endif

#
# checking for "Gentoo" style sysv scripts:
#

if USE_GENTOO

sysvdir = /etc/init.d
sysv_SCRIPTS = netatalk

$(sysv_SCRIPTS): rc.atalk.gentoo
	cp -f rc.atalk.gentoo $(sysv_SCRIPTS)
	chmod a+x $(sysv_SCRIPTS)

install-data-hook:
#	-rc-update add $(sysv_SCRIPTS) default

uninstall-startup:
#	-rc-update del $(sysv_SCRIPTS) default
#	rm -f $(DESTDIR)$(sysvdir)/$(sysv_SCRIPTS)

endif

#
# checking for "Debian" style sysv scripts:
#

if USE_DEBIAN

sysvdir = /etc/init.d
sysv_SCRIPTS = netatalk

$(sysv_SCRIPTS): rc.atalk.debian
	cp -f rc.atalk.debian $(sysv_SCRIPTS)
	chmod a+x $(sysv_SCRIPTS)

install-data-hook:
#	update-rc.d $(sysv_SCRIPTS) defaults 90 10

uninstall-startup:
#	rm -f $(DESTDIR)$(sysvdir)/$(sysv_SCRIPTS)
#	update-rc.d netatalk remove

endif


#
# defaults, no init scripts installed
#

if USE_UNDEF

install-data-hook:

uninstall-hook:

uninstall-startup: uninstall-am

endif

