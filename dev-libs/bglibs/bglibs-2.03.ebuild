# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI="6"

inherit toolchain-funcs

DESCRIPTION="Bruce Guenter's library collection"
HOMEPAGE="http://untroubled.org/bglibs/"
SRC_URI="http://untroubled.org/bglibs/archive/${P}.tar.gz"

LICENSE="LGPL-2.1"
SLOT="0/2"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~mips ~ppc ~ppc64 ~sparc ~x86"
IUSE=""

DOCS="ANNOUNCEMENT ChangeLog NEWS README TODO doc/latex"
HTML_DOCS="doc/html/*"

PATCHES=(
	"${FILESDIR}/${P}-headers.patch"
)

src_prepare() {
	default

	# bg-installer uses this variable instead of DESTDIR
	export install_prefix="${D}"
	# disable tests as we want to run them manually
	sed -i '/^all:/s/selftests//' Makefile
}

src_configure() {
	echo "/usr/bin" > conf-bin || die
	echo "/usr/include" > conf-include || die
	echo "/usr/$(get_libdir)" > conf-lib || die
	echo "/usr/share/man" > conf-man || die
	echo "$(tc-getCC) ${CFLAGS} ${CPPFLAGS}" > conf-cc || die
	echo "$(tc-getCC) ${LDFLAGS}" > conf-ld || die
}

src_test() {
	einfo "Running selftests"
	emake selftests || die
}
