# Copyright 2017-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="Virtual for ucspi-tcp"
HOMEPAGE=""
SRC_URI=""

LICENSE=""
SLOT="0/${PV}"
KEYWORDS="~alpha amd64 arm arm64 ~hppa ~ia64 ~loong ~m68k ~mips ppc ppc64 ~riscv ~s390 sparc x86"

RDEPEND="
	|| (
		net-misc/s6-networking
		sys-apps/ucspi-tcp[ipv6]
	)"
