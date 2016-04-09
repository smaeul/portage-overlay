# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5
PYTHON_COMPAT=( python2_7 )

inherit distutils-r1 mercurial

DESCRIPTION="Tools to manage KVM guests via the command line"
HOMEPAGE="https://hg.kasten-edv.de/kvm-tools"
EHG_REPO_URI="http://hg.kasten-edv.de/kvm-tools"

LICENSE="GPL-2+"
SLOT="0"
KEYWORDS=""
IUSE=""

DEPEND=""
RDEPEND="${DEPEND}
	app-emulation/qemu"

DOCS=( CHANGELOG.txt README.txt )
EXAMPLES=( domains/example )
PATCHES=( "${FILESDIR}"/${PN}-0.1.7.8_setup.py.patch )

python_install_all() {
	distutils-r1_python_install_all

	newinitd docs/qemu-kvm.example qemu-kvm
	insinto /etc/kvm/config
	doins config/kvm.cfg
	exeinto /etc/kvm/scripts
	doexe scripts/kvm-if{down,up}
	keepdir /etc/kvm/{auto,domains}
}

pkg_postinst() {
    elog "When you update qemu run 'generate-kvm-options --generate'"
    elog "to build a list of all available qemu options."
}
