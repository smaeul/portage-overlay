# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=6
PYTHON_COMPAT=( python2_7 python3_{4,5,6} )

inherit cron eutils multilib python-any-r1 toolchain-funcs

DESCRIPTION="A new cron system designed with secure operations in mind by Bruce Guenter"
HOMEPAGE="http://untroubled.org/bcron/"
SRC_URI="http://untroubled.org/bcron/archive/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"

RDEPEND="
	>=dev-libs/bglibs-2.00:=
	>=sys-process/cronbase-0.3.2
	virtual/mta
	sys-apps/ucspi-unix
"
DEPEND="${RDEPEND}
	${PYTHON_DEPS}
"

CRON_SYSTEM_CRONTAB="yes"
DOCS="ANNOUNCEMENT NEWS README TODO"

PATCHES=(
	"${FILESDIR}/${PN}-0.09-fix-socket-permissions.patch"
)

src_prepare() {
	default

	# bg-installer uses this variable instead of DESTDIR
	export install_prefix="${D}"
}

src_configure() {
	echo "/usr/bin" > conf-bin || die
	echo "/usr/share/man" > conf-man || die
	echo "$(tc-getCC) ${CFLAGS} ${CPPFLAGS}" > conf-cc || die
	echo "$(tc-getCC) ${LDFLAGS}" > conf-ld || die
}

src_install() {
	default

	keepdir /etc/bcron
	keepdir /etc/cron.d
	keepdir /var/spool/cron/crontabs
	keepdir /var/spool/cron/tmp

	for i in crontabs tmp
	do
		fowners cron:cron /var/spool/cron/$i
		fperms go-rwx /var/spool/cron/$i
	done

	insinto /etc
	doins "${FILESDIR}"/crontab

	insinto /var/lib/supervise/bcron
	doins bcron-sched.run

	insinto /var/lib/supervise/bcron/log
	doins bcron-sched-log.run

	insinto /var/lib/supervise/bcron-spool
	doins bcron-spool.run

	insinto /var/lib/supervise/bcron-update
	doins bcron-update.run
}

pkg_config() {
	cd "${ROOT}"var/lib/supervise/bcron
	[ -e run ] && cp run bcron-sched.run.`date +%Y%m%d%H%M%S`
	cp bcron-sched.run run
	chmod u+x run

	cd "${ROOT}"/var/lib/supervise/bcron/log
	[ -e run ] && cp run bcron-sched-log.run.`date +%Y%m%d%H%M%S`
	cp bcron-sched-log.run run
	chmod u+x run

	cd "${ROOT}"/var/lib/supervise/bcron-spool
	[ -e run ] && cp run bcron-spool.run.`date +%Y%m%d%H%M%S`
	cp bcron-spool.run run
	chmod u+x run

	cd "${ROOT}"/var/lib/supervise/bcron-update
	[ -e run ] && cp run bcron-update.run.`date +%Y%m%d%H%M%S`
	cp bcron-update.run run
	chmod u+x run

	[ ! -e "${ROOT}"/var/spool/cron/trigger ] && mkfifo "${ROOT}"var/spool/cron/trigger
	chown cron:cron /var/spool/cron/trigger
	chmod go-rwx /var/spool/cron/trigger
}

pkg_postinst() {
	echo
	elog "Run "
	elog "emerge --config =${PF}"
	elog "to create or update your run files (backups are created) in"
	elog "		/var/lib/supervise/bcron (bcron daemon) and"
	elog "		/var/lib/supervise/bcron-spool (crontab receiver) and"
	elog "		/var/lib/supervise/bcron-update (system crontab updater)"

	cron_pkg_postinst
}
