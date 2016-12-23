# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=6

inherit cmake-utils git-r3

DESCRIPTION=""
HOMEPAGE="http://ziglang.org/"
EGIT_REPO_URI="https://github.com/andrewrk/zig"

LICENSE="MIT"
SLOT="0"
KEYWORDS=""
IUSE="vim-syntax"

RDEPEND=">=sys-devel/llvm-3.9.0:=[clang]
	<sys-devel/llvm-4.0.0[clang]"
DEPEND="${RDEPEND}"

CMAKE_MAKEFILE_GENERATOR="ninja"
CMAKE_MIN_VERSION="2.8.5"

src_install() {
	cmake-utils_src_install

	dodoc doc/*.md
	mv example examples || die
	dodoc -r examples

	if use vim-syntax; then
		mv doc/vim doc/vimfiles || die
		insinto /usr/share/vim
		doins -r doc/vimfiles
	fi
}
