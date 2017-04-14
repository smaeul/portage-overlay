# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5

DESCRIPTION="Vanilla Linux kernel (binary package)"
HOMEPAGE="https://www.kernel.org"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 x86"

DEPEND="
	=sys-kernel/vanilla-sources-${PVR}
	sys-apps/debianutils
	sys-apps/kmod
"

KVER="${PV}-${PR}"
KVER="${KVER%-r0}"

S="${EPREFIX}/usr/src/linux-${KVER}"

src_compile() {
	:
}

src_install() {
	dobin usr/gen_init_cpio

	mkdir "${ED%/}/boot" || die
	installkernel "${KVER}" arch/x86/boot/bzImage System.map "${ED%/}/boot" || die

	mkdir -p "${ED%/}/lib/modules/${KVER}/kernel" || die
	find . -name '*.ko' | while read -r mod; do
		mkdir -p "${ED%/}/lib/modules/${KVER}/kernel/$(dirname "$mod")" || die
		cp "$mod" "${ED%/}/lib/modules/${KVER}/kernel/$mod" || die
		xz -9 "${ED%/}/lib/modules/${KVER}/kernel/$mod" || die
	done
	cp modules.builtin modules.order "${ED%/}/lib/modules/${KVER}" || die
	depmod -b "${ED%/}" "${KVER}" || die
}

pkg_postinst() {
	depmod "${KVER}"
}
