# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5

inherit rpm

DESCRIPTION="Open Virtual Machine Firmware"
HOMEPAGE="http://www.tianocore.org/ovmf/"
MY_PV="${PV}.b1509.ge1695f8"
RESTRICT="mirror"
SRC_URI="https://www.kraxel.org/repos/jenkins/edk2/edk2.git-ovmf-x64-0-${MY_PV}.noarch.rpm"

LICENSE="BSD FatBinPkg"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""

S="${WORKDIR}"

src_install() {
	insinto /usr/share/ovmf
	doins usr/share/edk2.git/ovmf-x64/*
	dodoc usr/share/doc/edk2.git-ovmf-x64/*
}
