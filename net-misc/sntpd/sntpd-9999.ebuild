# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit autotools git-r3

DESCRIPTION="A small SNTP client for UNIX systems, implementing RFC 1305 and RFC 4330"
HOMEPAGE="https://github.com/troglobit/sntpd"
EGIT_REPO_URI="https://github.com/troglobit/sntpd.git"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS=""
IUSE="debug"

PATCHES=( "${FILESDIR}/${P}-select.patch" )

src_prepare() {
	default

	eautoreconf
}

src_configure() {
	local myeconfargs=(
		$(use_enable debug)
		$(use_enable debug replay)
	)

	econf "${myeconfargs[@]}"
}
