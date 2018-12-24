# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

LLVM_MAX_SLOT=6
PYTHON_COMPAT=( python2_7 )

inherit llvm multiprocessing python-any-r1 versionator toolchain-funcs

if [[ ${PV} = *beta* ]]; then
	betaver=${PV//*beta}
	BETA_SNAPSHOT="${betaver:0:4}-${betaver:4:2}-${betaver:6:2}"
	MY_P="rustc-beta"
	SLOT="beta/${PV}"
	SRC="${BETA_SNAPSHOT}/rustc-beta-src.tar.xz"
	KEYWORDS=""
else
	ABI_VER="$(get_version_component_range 1-2)"
	SLOT="stable/${ABI_VER}"
	MY_P="rustc-${PV}"
	SRC="${MY_P}-src.tar.xz"
	KEYWORDS="~amd64 ~arm ~arm64 ~x86"
fi

case "${CHOST}" in
	armv7a-hardfloat-*)
		RUSTARCH=armv7 ;;
	arm*)
		RUSTARCH=arm ;;
	*)
		RUSTARCH=${CHOST%%-*} ;;
esac
case "${CHOST}" in
	armv7a-hardfloat-*)
		RUSTLIBC=${ELIBC/glibc/gnu}eabihf ;;
	arm*)
		RUSTLIBC=${ELIBC/glibc/gnu}eabi ;;
	*)
		RUSTLIBC=${ELIBC/glibc/gnu} ;;
esac
RUSTHOST=${RUSTARCH}-unknown-${KERNEL}-${RUSTLIBC}

RUST_STAGE0_VERSION="1.$(($(get_version_component_range 2) - 1)).0"

CARGO_DEPEND_VERSION="0.$(($(get_version_component_range 2) + 1)).0"

DESCRIPTION="Systems programming language from Mozilla"
HOMEPAGE="https://www.rust-lang.org/"

SRC_URI="https://static.rust-lang.org/dist/${SRC} -> rustc-${PV}-src.tar.xz
	amd64? (
		elibc_glibc? ( https://static.rust-lang.org/dist/rust-${RUST_STAGE0_VERSION}-x86_64-unknown-linux-gnu.tar.xz )
		elibc_musl? ( https://portage.smaeul.xyz/distfiles/bootstrap/rust-${RUST_STAGE0_VERSION}-x86_64-unknown-linux-musl.tar.xz )
	)
	arm? (
		elibc_glibc? (
			https://static.rust-lang.org/dist/rust-${RUST_STAGE0_VERSION}-arm-unknown-linux-gnueabi.tar.xz
			https://static.rust-lang.org/dist/rust-${RUST_STAGE0_VERSION}-armv7-unknown-linux-gnueabihf.tar.xz
		)
		elibc_musl? (
			https://portage.smaeul.xyz/distfiles/rust-${RUST_STAGE0_VERSION}-arm-unknown-linux-musleabi.tar.xz
			https://portage.smaeul.xyz/distfiles/rust-${RUST_STAGE0_VERSION}-armv7-unknown-linux-musleabihf.tar.xz
		)
	)
	arm64? (
		elibc_glibc? ( https://static.rust-lang.org/dist/rust-${RUST_STAGE0_VERSION}-aarch64-unknown-linux-gnu.tar.xz )
		elibc_musl? ( https://portage.smaeul.xyz/distfiles/rust-${RUST_STAGE0_VERSION}-aarch64-unknown-linux-musl.tar.xz )
	)
	x86? (
		elibc_glibc? ( https://static.rust-lang.org/dist/rust-${RUST_STAGE0_VERSION}-i686-unknown-linux-gnu.tar.xz )
		elibc_musl? ( https://portage.smaeul.xyz/distfiles/rust-${RUST_STAGE0_VERSION}-i686-unknown-linux-musl.tar.xz )
	)
"

LICENSE="|| ( MIT Apache-2.0 ) BSD-1 BSD-2 BSD-4 UoI-NCSA"

IUSE="debug doc extended jemalloc libressl system-llvm"

RDEPEND=">=app-eselect/eselect-rust-0.3_pre20150425
		extended? (
			libressl? ( dev-libs/libressl:0= )
			!libressl? ( dev-libs/openssl:0= )
			net-libs/http-parser:=
			net-libs/libssh2:=
			net-misc/curl:=[ssl]
			sys-libs/zlib:=
			!dev-util/rustfmt
			!dev-util/cargo
		)
		jemalloc? ( dev-libs/jemalloc )
		system-llvm? ( sys-devel/llvm )"
DEPEND="${RDEPEND}
	${PYTHON_DEPS}
	|| (
		>=sys-devel/gcc-4.7
		>=sys-devel/clang-3.5
	)
	!system-llvm? (
		dev-util/cmake
		dev-util/ninja
	)
"
PDEPEND="!extended? ( >=dev-util/cargo-${CARGO_DEPEND_VERSION} )"

PATCHES=(
	"${FILESDIR}/0001-Require-static-native-libraries-when-linking-static-.patch"
	"${FILESDIR}/0002-Remove-nostdlib-and-musl_root-from-musl-targets.patch"
	"${FILESDIR}/0003-Switch-musl-targets-to-link-dynamically-by-default.patch"
	"${FILESDIR}/0004-Prefer-libgcc_eh-over-libunwind-for-musl.patch"
	"${FILESDIR}/0005-Fix-LLVM-build.patch"
	"${FILESDIR}/0006-Fix-rustdoc-for-cross-targets.patch"
	"${FILESDIR}/0007-Add-openssl-configuration-for-musl-targets.patch"
	"${FILESDIR}/0008-Don-t-pass-CFLAGS-to-the-C-compiler.patch"
	"${FILESDIR}/0009-Support-big-endian-powerpc64-musl.patch"
	"${FILESDIR}/0011-Use-ELFv2-ABI-on-powerpc64-musl-LLVM-half.patch"
	"${FILESDIR}/0012-Use-ELFv2-ABI-on-powerpc64-musl-Rust-half.patch"
	"${FILESDIR}/0013-Disable-OpenSSL-assembly-for-powerpc64-musl.patch"
	"${FILESDIR}/0014-Support-powerpc-musl.patch"
	"${FILESDIR}/0015-liblibc.patch"
	"${FILESDIR}/0016-llvm.patch"
)
	#"${FILESDIR}/0010-Update-libc-to-0.2.43.patch"

S="${WORKDIR}/${MY_P}-src"

toml_usex() {
	usex "$1" true false
}

pkg_setup() {
	export RUST_BACKTRACE=1
	if use system-llvm; then
		llvm_pkg_setup
		local llvm_config="$(get_llvm_prefix "$LLVM_MAX_SLOT")/bin/llvm-config"

		export LLVM_LINK_SHARED=1
		export RUSTFLAGS="$RUSTFLAGS -Lnative=$("$llvm_config" --libdir)"
	fi

	python-any-r1_pkg_setup
}

src_prepare() {
	default

	"${WORKDIR}/rust-${RUST_STAGE0_VERSION}-${RUSTHOST}/install.sh" \
		--destdir="${WORKDIR}/stage0" \
		--prefix=/ \
		--components=rust-std-${RUSTHOST},rustc,cargo \
		--disable-ldconfig \
		|| die
}

src_configure() {
	cat <<- EOF > "${S}"/config.toml
		[llvm]
		ninja = true
		optimize = $(toml_usex !debug)
		release-debuginfo = $(toml_usex debug)
		assertions = $(toml_usex debug)
		[build]
		build = "${RUSTHOST}"
		host = ["${RUSTHOST}"]
		target = ["${RUSTHOST}"]
		cargo = "${WORKDIR}/stage0/bin/cargo"
		rustc = "${WORKDIR}/stage0/bin/rustc"
		docs = $(toml_usex doc)
		compiler-docs = $(toml_usex doc)
		submodules = false
		python = "${EPYTHON}"
		locked-deps = true
		vendor = true
		verbose = 0
		sanitizers = false
		profiler = false
		extended = $(toml_usex extended)
		[install]
		prefix = "${EPREFIX}/usr"
		libdir = "$(get_libdir)"
		docdir = "share/doc/${P}"
		mandir = "share/${P}/man"
		[rust]
		optimize = $(toml_usex !debug)
		debuginfo = $(toml_usex debug)
		debug-assertions = $(toml_usex debug)
		use-jemalloc = $(toml_usex jemalloc)
		default-linker = "$(tc-getCC)"
		channel = "${SLOT%%/*}"
		rpath = false
		optimize-tests = $(toml_usex !debug)
		dist-src = false
		[dist]
		src-tarball = false
		[target.${RUSTHOST}]
		cc = "$(tc-getCC)"
		cxx = "$(tc-getCXX)"
		linker = "$(tc-getCC)"
		ar = "$(tc-getAR)"
	EOF
	use system-llvm && cat <<- EOF >> "${S}"/config.toml
		llvm-config = "$(get_llvm_prefix "$LLVM_MAX_SLOT")/bin/llvm-config"
	EOF
}

src_compile() {
	./x.py build --config="${S}"/config.toml -j$(makeopts_jobs) || die
}

src_install() {
	env DESTDIR="${D}" ./x.py install || die

	mv "${D}/usr/bin/rustc" "${D}/usr/bin/rustc-${PV}" || die
	mv "${D}/usr/bin/rustdoc" "${D}/usr/bin/rustdoc-${PV}" || die
	mv "${D}/usr/bin/rust-gdb" "${D}/usr/bin/rust-gdb-${PV}" || die
	mv "${D}/usr/bin/rust-lldb" "${D}/usr/bin/rust-lldb-${PV}" || die

	rm "${D}/usr/$(get_libdir)/rustlib/components" || die
	rm "${D}/usr/$(get_libdir)/rustlib/install.log" || die
	rm "${D}/usr/$(get_libdir)/rustlib/manifest-rust-std-${RUSTHOST}" || die
	rm "${D}/usr/$(get_libdir)/rustlib/manifest-rustc" || die
	rm "${D}/usr/$(get_libdir)/rustlib/rust-installer-version" || die
	rm "${D}/usr/$(get_libdir)/rustlib/uninstall.sh" || die

	if use doc; then
		rm "${D}/usr/$(get_libdir)/rustlib/manifest-rust-docs" || die
		dodir "/usr/share/doc/${P}"
		mv "${D}/usr/share/doc/rust"/* "${D}/usr/share/doc/${P}" || die
		rmdir "${D}/usr/share/doc/rust" || die
	fi

	if use extended; then
		rm "${D}/usr/$(get_libdir)/rustlib/manifest-cargo" || die
		rm "${D}/usr/$(get_libdir)/rustlib/manifest-rls-preview" || die
		rm "${D}/usr/$(get_libdir)/rustlib/manifest-rust-analysis-$(rust_host ${ARCH})" || die
		rm "${D}/usr/$(get_libdir)/rustlib/manifest-rust-src" || die
		rm "${D}/usr/$(get_libdir)/rustlib/manifest-rustfmt-preview" || die

		rm "${D}/usr/share/doc/${P}/LICENSE-APACHE.old" || die
		rm "${D}/usr/share/doc/${P}/LICENSE-MIT.old" || die
	fi

	rm "${D}/usr/share/doc/${P}/LICENSE-APACHE" || die
	rm "${D}/usr/share/doc/${P}/LICENSE-MIT" || die

	docompress "/usr/share/${P}/man"

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

	elog "Rust installs a helper script for calling GDB and LLDB,"
	elog "for your convenience it is installed under /usr/bin/rust-{gdb,lldb}-${PV}."

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