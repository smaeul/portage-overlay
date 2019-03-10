# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=6

inherit cmake-utils git-r3

DESCRIPTION="Robust, optimal, and clear programming language"
HOMEPAGE="http://ziglang.org/"
EGIT_REPO_URI="https://github.com/ziglang/zig"

LICENSE="MIT"
SLOT="0"
KEYWORDS=""
IUSE=""

ALL_LLVM_TARGETS=( AArch64 AMDGPU ARM BPF Hexagon Lanai Mips MSP430
	NVPTX PowerPC Sparc SystemZ X86 XCore )
ALL_LLVM_TARGETS=${ALL_LLVM_TARGETS[*]/#/llvm_targets_}

RDEPEND="
	sys-devel/clang:7=
	sys-devel/llvm:7=[${ALL_LLVM_TARGETS// /,}]
	sys-devel/lld:=
"
DEPEND="${RDEPEND}
"

CMAKE_MIN_VERSION="2.8.5"

src_install() {
	cmake-utils_src_install

	dodoc doc/*.md
	mv example examples || die
	dodoc -r examples
}
