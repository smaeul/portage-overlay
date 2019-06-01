# Copyright 1999-2018 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit toolchain-funcs multiprocessing

MYP=${PN}-2019-${PV}-194D8

DESCRIPTION="Multi-Language Management"
HOMEPAGE="http://libre.adacore.com/"
SRC_URI="
	http://mirrors.cdn.adacore.com/art/5cdf8e8031e87a8f1d425093
		-> ${MYP}-src.tar.gz
	http://mirrors.cdn.adacore.com/art/5cdf916831e87a8f1d4250b5
		-> xmlada-2019-20190429-19B9D-src.tar.gz"
LICENSE="GPL-3"
SLOT="0"
KEYWORDS="amd64 x86"
IUSE=""

DEPEND="sys-devel/gcc[ada]"
RDEPEND="${DEPEND}"

S="${WORKDIR}"/${MYP}-src

PATCHES=(
	"${FILESDIR}"/${P}-gentoo.patch
)

src_configure() {
	emake BUILD=production prefix="${D}"usr setup
}

bin_progs="gprbuild gprconfig gprclean gprinstall gprname gprls"
lib_progs="gprlib gprbind"

src_compile() {
	GCC=${CHOST}-gcc
	GNATMAKE=${CHOST}-gnatmake
	local xmlada_src="../xmlada-2019-20190429-19B9D-src"
	incflags="-Isrc -Igpr/src -I${xmlada_src}/sax -I${xmlada_src}/dom \
		-I${xmlada_src}/schema -I${xmlada_src}/unicode \
		-I${xmlada_src}/input_sources"
	${GCC} -c ${CFLAGS} gpr/src/gpr_imports.c -o gpr_imports.o || die
	for bin in ${bin_progs}; do
		${GNATMAKE} -j$(makeopts_jobs) ${incflags} $ADAFLAGS ${bin}-main \
			-o ${bin} -cargs $CFLAGS -largs $LDFLAGS gpr_imports.o || die
	done
	for lib in $lib_progs; do
		${GNATMAKE} -j$(makeopts_jobs) ${incflags} $ADAFLAGS ${lib} \
			-cargs $CFLAGS -largs $LDFLAGS gpr_imports.o || die
	done
}

src_install() {
	dobin ${bin_progs}
	exeinto /usr/libexec/gprbuild
	doexe ${lib_progs}
	insinto /usr/share/gprconfig
	doins share/gprconfig/*
	insinto /usr/share/gpr
	doins share/_default.gpr
	einstalldocs
}
