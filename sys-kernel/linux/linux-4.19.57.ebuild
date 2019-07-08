# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=5

inherit linux-info

DESCRIPTION="Linux kernel (binary package)"
HOMEPAGE="https://www.kernel.org"

LICENSE="GPL-2"
SLOT="${PV}"
KEYWORDS="amd64 x86"

DEPEND="
	sys-apps/debianutils
	sys-apps/kmod
	virtual/linux-sources
"

KVER="${PV}-${PR}"
KVER="${KVER%-r0}"

S="${EPREFIX}/usr/src/linux"

src_compile() {
	set_arch_to_kernel
	test "$(make M="$T" kernelversion)" = "$PV" || \
		die "Package version does not match source version"
}

src_install() {
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
