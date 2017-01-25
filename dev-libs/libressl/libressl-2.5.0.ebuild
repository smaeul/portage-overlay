# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=6

inherit eutils multilib-minimal

DESCRIPTION="Free version of the SSL/TLS protocol forked from OpenSSL"
HOMEPAGE="http://www.libressl.org/"
SRC_URI="http://ftp.openbsd.org/pub/OpenBSD/LibreSSL/${P}.tar.gz"

LICENSE="ISC openssl"
# Reflects ABI of libcrypto.so and libssl.so.  Since these can differ,
# we'll try to use the max of either.  However, if either change between
# versions, we have to change the subslot to trigger rebuild of consumers.
SLOT="0/39"
KEYWORDS="~amd64 ~arm ~hppa ~mips ~ppc ~ppc64 ~x86"
IUSE="+asm static-libs"

RDEPEND="!dev-libs/openssl:0"
DEPEND="${RDEPEND}"
PDEPEND="app-misc/ca-certificates"

PATCHES=(
	"${FILESDIR}/${PN}-2.5.0-altchains-1.patch"
	"${FILESDIR}/${PN}-2.5.0-altchains-2.patch"
	"${FILESDIR}/${PN}-2.5.0-altchains-3.patch"
	"${FILESDIR}/${PN}-2.5.0-altchains-4.patch"
	"${FILESDIR}/${PN}-2.5.0-altchains-5.patch"
	"${FILESDIR}/${PN}-2.5.0-altchains-6.patch"
	"${FILESDIR}/${PN}-2.5.0-altchains-7.patch"
)

src_prepare() {
	default

	touch crypto/Makefile.in

	sed -i \
		-e '/^[ \t]*CFLAGS=/s#-g ##' \
		-e '/^[ \t]*CFLAGS=/s#-g"#"#' \
		-e '/^[ \t]*CFLAGS=/s#-O2 ##' \
		-e '/^[ \t]*CFLAGS=/s#-O2"#"#' \
		-e '/^[ \t]*USER_CFLAGS=/s#-O2 ##' \
		-e '/^[ \t]*USER_CFLAGS=/s#-O2"#"#' \
		configure || die "fixing CFLAGS failed"

	sed -i 's#cert.pem ##' \
		apps/openssl/Makefile.{am,in} || die "fixing CA install failed"
	sed -i 's#/cert.pem#/certs/ca-certificates.crt#' \
		$(find apps crypto tls -type f) || die "fixing CA path failed"
}

multilib_src_configure() {
	ECONF_SOURCE="${S}" econf \
		$(use_enable asm) \
		$(use_enable static-libs static)
}

multilib_src_test() {
	emake check
}

multilib_src_install_all() {
	einstalldocs
	prune_libtool_files
}
