# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5

inherit git-r3 cmake-utils

DESCRIPTION="Faster replacement for i3-dmenu-desktop."
HOMEPAGE="https://github.com/enkore/j4-dmenu-desktop"
EGIT_REPO_URI="https://github.com/enkore/j4-dmenu-desktop.git"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS=""
IUSE="test"

DEPEND=""
RDEPEND="x11-misc/dmenu"

src_configure() {
	local mycmakeargs=(
		$(cmake-utils_use_no test TESTS)
	)
	cmake-utils_src_configure
}
