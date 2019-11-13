# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit multilib-minimal toolchain-funcs

DESCRIPTION="GCC libssp_nonshared.a, in LIBDIR, for bootstrapping"
HOMEPAGE="https://gcc.gnu.org"
LICENSE="|| ( GPL-3+ gcc-runtime-library-exception-3.1 )"
SLOT="0"
KEYWORDS="amd64 arm arm64 ppc ppc64 x86"
IUSE=""

S="${WORKDIR}"

multilib_src_compile() {
	$(tc-getCC) ${CFLAGS} -c -o ssp-local.o "${FILESDIR}"/ssp-local.c || die
	$(tc-getAR) -rcs libssp_nonshared.a ssp-local.o || die
}

multilib_src_install() {
	dolib.a libssp_nonshared.a
}
