# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

LLVM_MAX_SLOT=4
PYTHON_COMPAT=( python2_7 )

inherit python-any-r1 versionator toolchain-funcs llvm

if [[ ${PV} = *beta* ]]; then
	betaver=${PV//*beta}
	BETA_SNAPSHOT="${betaver:0:4}-${betaver:4:2}-${betaver:6:2}"
	MY_P="rustc-beta"
	SLOT="beta/${PV}"
	SRC="${BETA_SNAPSHOT}/rustc-beta-src.tar.gz"
	KEYWORDS=""
else
	ABI_VER="$(get_version_component_range 1-2)"
	SLOT="stable/${ABI_VER}"
	MY_P="rustc-${PV}"
	SRC="${MY_P}-src.tar.gz"
	KEYWORDS="~amd64 ~x86"
fi

CTARGET=${CHOST/gentoo/unknown}
STAGE0_VERSION="1.$(($(get_version_component_range 2) - 1)).0"
RUST_STAGE0="rust-${STAGE0_VERSION}-${CTARGET}"

DESCRIPTION="Systems programming language from Mozilla"
HOMEPAGE="https://www.rust-lang.org/"

SRC_URI="https://static.rust-lang.org/dist/${SRC} -> rustc-${PV}-src.tar.gz
	http://portage.smaeul.xyz/distfiles/${RUST_STAGE0}.tar.gz
"

LICENSE="|| ( MIT Apache-2.0 ) BSD-1 BSD-2 BSD-4 UoI-NCSA"

IUSE="debug doc jemalloc system-llvm"
REQUIRED_USE=""

RDEPEND="
	system-llvm? ( sys-devel/llvm:= )
"
DEPEND="${RDEPEND}
	${PYTHON_DEPS}
	>=sys-devel/gcc-4.7
	!system-llvm? (
		dev-util/cmake
		dev-util/ninja
	)
"
PDEPEND=">=app-eselect/eselect-rust-0.3_pre20150425
	|| ( dev-util/cargo dev-util/cargo-bin )
"

PATCHES=(
	${FILESDIR}/0001-Factor-out-helper-for-getting-C-runtime-linkage.patch
	${FILESDIR}/0002-Link-libgcc_s-over-libunwind-on-musl.patch
	${FILESDIR}/0003-Support-dynamic-linking-for-musl-based-targets.patch
	${FILESDIR}/0004-Presence-of-libraries-does-not-depend-on-architectur.patch
	${FILESDIR}/0005-completely-remove-musl_root-and-its-c-library-overri.patch
	${FILESDIR}/0006-liblibc.patch
)

S="${WORKDIR}/${MY_P}-src"

toml_usex() {
	usex "$1" true false
}

pkg_setup() {
	llvm_pkg_setup
	python-any-r1_pkg_setup
}

src_prepare() {
	default

	"${WORKDIR}/${RUST_STAGE0}/install.sh" \
		--prefix="${WORKDIR}/stage0" \
		--components=rust-std-${CTARGET},rustc,cargo \
		--disable-ldconfig \
		|| die
}

src_configure() {
	cat <<- EOF > "${S}"/config.toml
		[llvm]
		ninja = true
		[build]
		build = "${CTARGET}"
		host = ["${CTARGET}"]
		target = ["${CTARGET}"]
		cargo = "${WORKDIR}/stage0/bin/cargo"
		rustc = "${WORKDIR}/stage0/bin/rustc"
		docs = $(toml_usex doc)
		compiler-docs = $(toml_usex doc)
		submodules = false
		python = "${EPYTHON}"
		locked-deps = true
		vendor = true
		verbose = 2
		[install]
		prefix = "${EPREFIX}/usr"
		docdir = "share/doc/${P}"
		libdir = "$(get_libdir)"
		mandir = "share/${P}/man"
		[rust]
		optimize = $(toml_usex !debug)
		debug-assertions = $(toml_usex debug)
		debuginfo = $(toml_usex debug)
		debug-lines = $(toml_usex debug)
		use-jemalloc = $(toml_usex jemalloc)
		channel = "${SLOT%%/*}"
		rpath = false
		[target.${CTARGET}]
		cc = "$(tc-getCC)"
		cxx = "$(tc-getCXX)"
	EOF
	use system-llvm && cat <<- EOF >> "${S}"/config.toml
		llvm-config = "$(get_llvm_prefix)/bin/llvm-config"
	EOF
}

src_compile() {
	export RUST_BACKTRACE=1
	use system-llvm && export LLVM_LINK_SHARED=1

	./x.py build || die
}

src_install() {
	env DESTDIR="${D}" ./x.py install || die

	rm "${D}/usr/lib/rustlib/components" || die
	rm "${D}/usr/lib/rustlib/install.log" || die
	rm "${D}/usr/lib/rustlib/manifest-rust-std-x86_64-unknown-linux-musl" || die
	rm "${D}/usr/lib/rustlib/manifest-rustc" || die
	rm "${D}/usr/lib/rustlib/rust-installer-version" || die
	rm "${D}/usr/lib/rustlib/uninstall.sh" || die

	mv "${D}/usr/bin/rustc" "${D}/usr/bin/rustc-${PV}" || die
	mv "${D}/usr/bin/rustdoc" "${D}/usr/bin/rustdoc-${PV}" || die
	mv "${D}/usr/bin/rust-gdb" "${D}/usr/bin/rust-gdb-${PV}" || die
	mv "${D}/usr/bin/rust-lldb" "${D}/usr/bin/rust-lldb-${PV}" || die

	dodoc COPYRIGHT

	cat <<-EOF > "${T}"/50${P}
		MANPATH="/usr/share/${P}/man"
	EOF
	doenvd "${T}"/50${P}

	cat <<-EOF > "${T}/provider-${P}"
		/usr/bin/rustdoc
		/usr/bin/rust-gdb
		/usr/bin/rust-lldb
	EOF
	dodir /etc/env.d/rust
	insinto /etc/env.d/rust
	doins "${T}/provider-${P}"
}

pkg_postinst() {
	eselect rust update --if-unset

	elog "Rust installs a helper script for calling GDB now,"
	elog "for your convenience it is installed under /usr/bin/rust-gdb-${PV}."

	if has_version app-editors/emacs || has_version app-editors/emacs-vcs; then
		elog "install app-emacs/rust-mode to get emacs support for rust."
	fi

	if has_version app-editors/gvim || has_version app-editors/vim; then
		elog "install app-vim/rust-vim to get vim support for rust."
	fi

	if has_version 'app-shells/zsh'; then
		elog "install app-shells/rust-zshcomp to get zsh completion for rust."
	fi
}

pkg_postrm() {
	eselect rust unset --if-invalid
}
