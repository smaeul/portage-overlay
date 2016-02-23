# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5

inherit fcaps git-r3 toolchain-funcs

DESCRIPTION="generates a status bar for dzen2, xmobar or similar (mpd support)"
HOMEPAGE="https://github.com/Gravemind/i3status"
EGIT_REPO_URI="https://github.com/Gravemind/i3status.git"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

RDEPEND="dev-libs/confuse
	dev-libs/libnl:3
	>=dev-libs/yajl-2.0.2
	media-libs/alsa-lib
	media-libs/libmpdclient
	media-sound/pulseaudio"
DEPEND="${RDEPEND}
	app-text/asciidoc
	virtual/pkgconfig"

src_prepare() {
	epatch "${FILESDIR}"/connection.patch
	epatch "${FILESDIR}"/signal.patch
	sed -e "/@echo/d" -e "s:@\$(:\$(:g" -e "/setcap/d" \
		-e '/CFLAGS+=-g/d' -i Makefile || die
	rm -rf man/${PN}.1  # man not regenerated in tarball
}

src_compile() {
	emake CC="$(tc-getCC)"
}

pkg_postinst() {
	fcaps cap_net_admin usr/bin/i3status
	einfo "${PN} can be used with any of the following programs:"
	einfo "   i3bar (x11-wm/i3)"
	einfo "   x11-misc/xmobar"
	einfo "   x11-misc/dzen"
	einfo "Please refer to manual: man ${PN}"
}
