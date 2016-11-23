# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5
inherit autotools eutils prefix

DESCRIPTION="Text based WWW browser, supports tables and frames"
HOMEPAGE="http://w3m.sourceforge.net/"
SRC_URI="https://github.com/tats/w3m/archive/v0.5.3+git20161120.tar.gz"
RESTRICT="mirror"

LICENSE="w3m"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="X fbcon gpm gtk imlib libressl lynxkeymap nls nntp ssl unicode xface l10n_ja"

# We cannot build w3m with gtk+2 w/o X because gtk+2 ebuild doesn't
# allow us to build w/o X, so we have to give up framebuffer w3mimg....
RDEPEND=">=sys-libs/ncurses-5.2-r3:0=
	>=sys-libs/zlib-1.1.3-r2
	>=dev-libs/boehm-gc-6.2
	X? ( x11-libs/libXext x11-libs/libXdmcp )
	gtk? ( x11-libs/gdk-pixbuf )
	!gtk? ( imlib? ( >=media-libs/imlib2-1.1.0[X] ) )
	xface? ( media-libs/compface )
	gpm? ( >=sys-libs/gpm-1.19.3-r5 )
	ssl? (
		!libressl? ( dev-libs/openssl:0= )
		libressl? ( dev-libs/libressl:0= )
	)"
DEPEND="${RDEPEND}
	virtual/pkgconfig"

S="${WORKDIR}/${PN}-0.5.3-git20161120"

src_prepare() {
	epatch \
		"${FILESDIR}"/${PN}-0.5.3-underlinking.patch
	ecvs_clean
	sed -i -e "/^AR=/s/ar/$(tc-getAR)/" {.,w3mimg,libwc}/Makefile.in || die
	hprefixify acinclude.m4
	eautoconf
}

src_configure() {
	local myconf imagelibval imageval

	if use gtk ; then
		imagelibval="gtk2"
	elif use imlib ; then
		imagelibval="imlib2"
	fi

	if [ ! -z "${imagelibval}" ] ; then
		use X && imageval="${imageval}${imageval:+,}x11"
		use X && use fbcon && imageval="${imageval}${imageval:+,}fb"
	fi

	# emacs-w3m doesn't like "--enable-m17n --disable-unicode,"
	# so we better enable or disable both. Default to enable
	# m17n and unicode, see bug #47046.
	if use l10n_ja ; then
		if use unicode ; then
			myconf="${myconf} --enable-japanese=U"
		else
			myconf="${myconf} --enable-japanese=E"
		fi
	elif use unicode ; then
		myconf="${myconf} --with-charset=UTF-8"
	else
		myconf="${myconf} --with-charset=US-ASCII"
	fi

	# lynxkeymap IUSE flag. bug #49397
	if use lynxkeymap ; then
		myconf="${myconf} --enable-keymap=lynx"
	else
		myconf="${myconf} --enable-keymap=w3m"
	fi

	econf \
		--with-editor="${EPREFIX}/usr/bin/vi" \
		--with-mailer="${EPREFIX}/bin/mail" \
		--with-browser="${EPREFIX}/usr/bin/xdg-open" \
		--with-termlib=yes \
		--enable-image=${imageval:-no} \
		--with-imagelib="${imagelibval:-no}" \
		--without-migemo \
		--enable-m17n \
		--enable-unicode \
		$(use_enable gpm mouse) \
		$(use_enable nls) \
		$(use_enable nntp) \
		$(use_enable ssl digest-auth) \
		$(use_with ssl) \
		$(use_enable xface) \
		${myconf}
}

src_install() {

	emake DESTDIR="${D}" install

	# http://www.sic.med.tohoku.ac.jp/~satodai/w3m-dev/200307.month/3944.html
	insinto /etc/${PN}
	newins "${FILESDIR}/${PN}.mailcap" mailcap

	insinto /usr/share/${PN}/Bonus
	doins Bonus/*
	dodoc README NEWS TODO ChangeLog
	docinto doc-en ; dodoc doc/*
	if use l10n_ja ; then
		docinto doc-jp ; dodoc doc-jp/*
	else
		rm -rf "${ED}"/usr/share/man/ja || die
	fi
}
