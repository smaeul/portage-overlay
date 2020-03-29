# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit autotools fcaps git-r3

DESCRIPTION="generates a status bar for dzen2, xmobar or similar"
HOMEPAGE="https://i3wm.org/i3status/"
EGIT_REPO_URI="https://github.com/smaeul/i3status.git"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64 ~arm ~x86"
IUSE="pulseaudio"

BDEPEND="virtual/pkgconfig"
RDEPEND="
	!x11-misc/i3status
	>=dev-libs/yajl-2.0.2
	dev-libs/confuse:=
	dev-libs/libnl:3
	media-libs/alsa-lib
	media-libs/libmpdclient
	pulseaudio? ( || ( media-sound/pulseaudio media-sound/apulse[sdk] ) )
"
DEPEND="
	${RDEPEND}
	app-text/asciidoc
	app-text/xmlto
"

src_prepare() {
	default

	eautoreconf
}

src_configure() {
	local myeconfargs=(
		--disable-builddir
		$(use_enable pulseaudio)
	)

	econf "${myeconfargs[@]}"
}

pkg_postinst() {
	fcaps cap_net_admin usr/bin/i3status
	einfo "${PN} can be used with any of the following programs:"
	einfo "   i3bar (x11-wm/i3)"
	einfo "   x11-misc/xmobar"
	einfo "   x11-misc/dzen"
	einfo "Please refer to manual: man i3status"
}
