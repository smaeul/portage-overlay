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
	KEYWORDS="~amd64 ~arm ~x86"
fi

CTARGET=${CHOST/gentoo/unknown}
STAGE0_VERSION="1.$(($(get_version_component_range 2) - 1)).0"
RUST_STAGE0="rust-${STAGE0_VERSION}-${CTARGET}"

DESCRIPTION="Systems programming language from Mozilla"
HOMEPAGE="https://www.rust-lang.org/"

SRC_URI="https://static.rust-lang.org/dist/${SRC} -> rustc-${PV}-src.tar.gz
	http://portage.smaeul.xyz/distfiles/${RUST_STAGE0}.tar.xz
"

LICENSE="|| ( MIT Apache-2.0 ) BSD-1 BSD-2 BSD-4 UoI-NCSA"

IUSE="debug doc jemalloc system-llvm"
REQUIRED_USE=""

RDEPEND="
	system-llvm? ( sys-devel/llvm:4 )
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
	"${FILESDIR}/0001-Remove-incorrect-special-case-of-mips-musl.patch"
	"${FILESDIR}/0002-Improve-explanation-of-musl_root.patch"
	"${FILESDIR}/0003-Infer-a-default-musl_root-for-native-builds.patch"
	"${FILESDIR}/0004-Copy-musl-startup-objects-before-building-std.patch"
	"${FILESDIR}/0005-Introduce-crt_static-target-option-in-config.toml.patch"
	"${FILESDIR}/0006-Inline-crt-static-choice-for-pc-windows-msvc.patch"
	"${FILESDIR}/0007-Factor-out-a-helper-for-the-getting-C-runtime-linkag.patch"
	"${FILESDIR}/0008-Introduce-temporary-target-feature-crt_static_respec.patch"
	"${FILESDIR}/0009-Introduce-target-feature-crt_static_allows_dylibs.patch"
	"${FILESDIR}/0010-Disable-PIE-when-linking-statically.patch"
	"${FILESDIR}/0011-Tell-the-linker-when-we-want-to-link-a-static-execut.patch"
	"${FILESDIR}/0012-Update-libunwind-dependencies-for-musl.patch"
	"${FILESDIR}/0013-Do-not-assume-libunwind.a-is-available.patch"
	"${FILESDIR}/0014-Support-dynamic-linking-for-musl-based-targets.patch"
	"${FILESDIR}/0015-Update-ignored-tests-for-dynamic-musl.patch"
	"${FILESDIR}/0016-Require-rlibs-for-dependent-crates-when-linking-stat.patch"
	"${FILESDIR}/0017-Remove-nostdlib-and-musl_root-from-musl-targets.patch"
	"${FILESDIR}/0018-Native-library-linkage.patch"
	"${FILESDIR}/0019-liblibc.patch"
	"${FILESDIR}/0020-libunwind.patch"
	"${FILESDIR}/llvm-musl-fixes.patch"
	"${FILESDIR}/llvm-nostatic.patch"
)

S="${WORKDIR}/${MY_P}-src"

toml_usex() {
	usex "$1" true false
}

pkg_setup() {
	use system-llvm && llvm_pkg_setup

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
		crt_static = false
		[dist]
		src-tarball = false
	EOF
	use system-llvm && cat <<- EOF >> "${S}"/config.toml
		llvm-config = "$(get_llvm_prefix "$LLVM_MAX_SLOT")/bin/llvm-config"
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
	rm "${D}/usr/lib/rustlib/manifest-rust-std-${CTARGET}" || die
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
