# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit git-r3 toolchain-funcs

DESCRIPTION="Android platform tools (adb, fastboot, and mkbootimg)"
HOMEPAGE="https://android.googlesource.com/platform/system/core"
EGIT_REPO_URI="https://github.com/smaeul/android-tools"

# The entire source code is Apache-2.0, except for fastboot which is BSD-2.
LICENSE="Apache-2.0 BSD-2"
SLOT="0"
KEYWORDS=""
IUSE="static"

RDEPEND="sys-libs/zlib:="
# ADB only works with BoringSSL (not LibreSSL or OpenSSL).
# BoringSSL uses perl in its build system.
# Android core libraries use stdatomic.h from C++, which breaks g++.
# Both Android libraries and BoringSSL use several clang-only warning flags.
DEPEND="
	${RDEPEND}
	dev-lang/perl
	sys-devel/clang
"

src_compile() {
	if use static; then
		LDFLAGS+=" -static"
	else
		ewarn "Installed binaries might depend on libcxx/libunwind, set USE=static to avoid."
	fi

	default
}
