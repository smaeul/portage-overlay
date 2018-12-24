# Copyright 1999-2018 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=6

LLVM_MAX_SLOT=7
PYTHON_COMPAT=( python3_{5,6,7} )

inherit llvm multiprocessing python-any-r1 toolchain-funcs versionator

ABI_VER="$(get_version_component_range 1-2)"
SLOT="stable/${ABI_VER}"
MY_P="rustc-${PV}"
SRC="${MY_P}-src.tar.xz"
KEYWORDS="~amd64 ~arm ~arm64 ~ppc ~ppc64 ~x86"

RUST_STAGE0_VERSION="1.$(($(get_version_component_range 2) - 0)).1"
CARGO_DEPEND_VERSION="0.$(($(get_version_component_range 2) + 1)).0"

DESCRIPTION="Systems programming language from Mozilla"
HOMEPAGE="https://www.rust-lang.org/"

SRC_URI="https://static.rust-lang.org/dist/${SRC} -> rustc-${PV}-src.tar.xz
	amd64? ( https://portage.smaeul.xyz/distfiles/rust-${RUST_STAGE0_VERSION}-x86_64-gentoo-linux-musl.tar.xz )
	arm? ( https://portage.smaeul.xyz/distfiles/rust-${RUST_STAGE0_VERSION}-armv7a-unknown-linux-musleabihf.tar.xz )
	arm64? ( https://portage.smaeul.xyz/distfiles/rust-${RUST_STAGE0_VERSION}-aarch64-gentoo-linux-musl.tar.xz )
	ppc? ( https://portage.smaeul.xyz/distfiles/rust-${RUST_STAGE0_VERSION}-powerpc-gentoo-linux-musl.tar.xz )
	ppc64? ( https://portage.smaeul.xyz/distfiles/rust-${RUST_STAGE0_VERSION}-powerpc64-linux-musl.tar.xz )
	x86? ( https://portage.smaeul.xyz/distfiles/rust-${RUST_STAGE0_VERSION}-i686-gentoo-linux-musl.tar.xz )
"

ALL_LLVM_TARGETS=( AArch64 AMDGPU ARM BPF Hexagon Lanai Mips MSP430
	NVPTX PowerPC Sparc SystemZ X86 XCore )
ALL_LLVM_TARGETS=( "${ALL_LLVM_TARGETS[@]/#/llvm_targets_}" )
LLVM_TARGET_USEDEPS=${ALL_LLVM_TARGETS[@]/%/=}

LICENSE="|| ( MIT Apache-2.0 ) BSD-1 BSD-2 BSD-4 UoI-NCSA"

IUSE="cargo clippy debug doc jemalloc libressl rls rustfmt system-llvm ${ALL_LLVM_TARGETS[*]}"

RDEPEND=">=app-eselect/eselect-rust-0.3_pre20150425
	jemalloc? ( dev-libs/jemalloc )
	cargo? (
		!libressl? ( dev-libs/openssl:0= )
		libressl? ( dev-libs/libressl:0= )
		net-libs/http-parser:=
		net-libs/libssh2:=
		net-misc/curl:=[ssl]
		sys-libs/zlib:=
	)
	system-llvm? ( sys-devel/llvm:=[${LLVM_TARGET_USEDEPS// /,}] )"
DEPEND="${RDEPEND}
	${PYTHON_DEPS}
	|| (
		>=sys-devel/gcc-4.7
		>=sys-devel/clang-3.5
	)
	cargo? ( !dev-util/cargo )
	rustfmt? ( !dev-util/rustfmt )
	!system-llvm? (
		dev-util/cmake
		dev-util/ninja
	)
"
PDEPEND="!cargo? ( >=dev-util/cargo-${CARGO_DEPEND_VERSION} )"

REQUIRED_USE="|| ( ${ALL_LLVM_TARGETS[*]} )"

PATCHES=(
	"${FILESDIR}/0001-Don-t-pass-CFLAGS-to-the-C-compiler.patch"
	"${FILESDIR}/0002-Fix-LLVM-build.patch"
	"${FILESDIR}/0003-Allow-rustdoc-to-work-when-cross-compiling-on-musl.patch"
	"${FILESDIR}/0004-Require-static-native-libraries-when-linking-static-.patch"
	"${FILESDIR}/0005-Remove-nostdlib-and-musl_root-from-musl-targets.patch"
	"${FILESDIR}/0006-Prefer-libgcc_eh-over-libunwind-for-musl.patch"
	"${FILESDIR}/0007-Add-powerpc-unknown-linux-musl-target.patch"
	"${FILESDIR}/0008-Fix-powerpc64-ELFv2-big-endian-struct-passing-ABI.patch"
	"${FILESDIR}/0009-Use-the-ELFv2-ABI-on-powerpc64-musl.patch"
	"${FILESDIR}/0010-Add-powerpc64-unknown-linux-musl-target.patch"
	"${FILESDIR}/0011-Add-missing-OpenSSL-configurations-for-musl-targets.patch"
	"${FILESDIR}/0012-rustc_data_structures-use-libc-types-constants-in-fl.patch"
	"${FILESDIR}/0013-runtest-Fix-proc-macro-tests-on-musl-hosts.patch"
	"${FILESDIR}/0014-Fix-double_check-tests-on-big-endian-targets.patch"
	"${FILESDIR}/0015-test-invalid_const_promotion-Accept-SIGTRAP-as-a-val.patch"
	"${FILESDIR}/0016-test-linkage-visibility-Ensure-symbols-are-visible-t.patch"
	"${FILESDIR}/0017-x.py-Use-python3-instead-of-python.patch"
	"${FILESDIR}/0018-test-target-feature-gate-Only-run-on-relevant-target.patch"
	"${FILESDIR}/0019-test-use-extern-for-plugins-Don-t-assume-multilib.patch"
	"${FILESDIR}/0020-test-sysroot-crates-are-unstable-Fix-test-when-rpath.patch"
	"${FILESDIR}/0021-Ignore-broken-and-non-applicable-tests.patch"
	"${FILESDIR}/0022-Link-stage-2-tools-dynamically-to-libstd.patch"
	"${FILESDIR}/0023-Move-debugger-scripts-to-usr-share-rust.patch"
	"${FILESDIR}/0024-Add-gentoo-target-specs.patch"
	"${FILESDIR}/0025-Add-powerpc64-linux-musl-target-spec.patch"
	"${FILESDIR}/0030-liblibc-linkage.patch"
	"${FILESDIR}/0031-liblibc-1b130d4c349d.patch"
	"${FILESDIR}/0040-rls-atomics.patch"
	"${FILESDIR}/0050-llvm.patch"
	"${FILESDIR}/0051-llvm-D45520.patch"
	"${FILESDIR}/0052-llvm-D51108.patch"
	"${FILESDIR}/0053-llvm-D52013.patch"
	"${FILESDIR}/0054-llvm-secureplt.patch"
)

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

	"${WORKDIR}/rust-${RUST_STAGE0_VERSION}-${CHOST}/install.sh" \
		--destdir="${WORKDIR}/stage0" \
		--prefix=/ \
		--components=rust-std-${CHOST},rustc,cargo \
		--disable-ldconfig \
		|| die
}

src_configure() {
	local extended="false" tools=""

	for tool in cargo clippy rls rustfmt; do
		if use $tool; then
			extended="true"
			tools+='"'"$tool"'", '
		fi
	done

	cat <<- EOF > "${S}"/config.toml
		[llvm]
		ninja = true
		optimize = $(toml_usex !debug)
		release-debuginfo = $(toml_usex debug)
		assertions = $(toml_usex debug)
		targets = "${LLVM_TARGETS// /;}"
		[build]
		build = "${CHOST}"
		host = ["${CHOST}"]
		target = ["${CHOST}"]
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
		extended = ${extended}
		tools = [${tools}]
		[install]
		prefix = "${EPREFIX}/usr"
		libdir = "lib"
		docdir = "share/doc/${P}"
		mandir = "share/${P}/man"
		[rust]
		optimize = $(toml_usex !debug)
		debuginfo = $(toml_usex debug)
		debug-assertions = $(toml_usex debug)
		use-jemalloc = $(toml_usex jemalloc)
		default-linker = "$(tc-getCC)"
		channel = "stable"
		rpath = false
		optimize-tests = $(toml_usex !debug)
		dist-src = false
		[dist]
		src-tarball = false
		[target.${CHOST}]
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

src_test() {
	./x.py test -j$(makeopts_jobs) --no-doc --no-fail-fast \
		src/test/codegen \
		src/test/codegen-units \
		src/test/compile-fail \
		src/test/compile-fail-fulldeps \
		src/test/incremental \
		src/test/incremental-fulldeps \
		src/test/mir-opt \
		src/test/parse-fail \
		src/test/pretty \
		src/test/run-fail \
		src/test/run-fail/pretty \
		src/test/run-fail-fulldeps \
		src/test/run-fail-fulldeps/pretty \
		src/test/run-make \
		src/test/run-make-fulldeps \
		src/test/run-pass \
		src/test/run-pass/pretty \
		src/test/run-pass-fulldeps \
		src/test/run-pass-fulldeps/pretty \
		src/test/ui \
		src/test/ui-fulldeps
}

src_install() {
	env DESTDIR="${D}" ./x.py install || die

	mv "${D}/usr/bin/rustc" "${D}/usr/bin/rustc-${PV}" || die
	mv "${D}/usr/bin/rustdoc" "${D}/usr/bin/rustdoc-${PV}" || die
	mv "${D}/usr/bin/rust-gdb" "${D}/usr/bin/rust-gdb-${PV}" || die
	mv "${D}/usr/bin/rust-lldb" "${D}/usr/bin/rust-lldb-${PV}" || die

	rm "${D}/usr/lib"/*.so || die
	rm "${D}/usr/lib/rustlib/components" || die
	rm "${D}/usr/lib/rustlib/install.log" || die
	rm "${D}/usr/lib/rustlib"/manifest-* || die
	rm "${D}/usr/lib/rustlib/rust-installer-version" || die
	rm "${D}/usr/lib/rustlib/uninstall.sh" || die

	if use cargo; then
		mv "${D}/usr/bin/cargo" "${D}/usr/bin/cargo-${PV}" || die
	fi
	if use clippy; then
		mv "${D}/usr/bin/cargo-clippy" "${D}/usr/bin/cargo-clippy-${PV}" || die
		mv "${D}/usr/bin/clippy-driver" "${D}/usr/bin/clippy-driver-${PV}" || die
	fi
	if use rls; then
		mv "${D}/usr/bin/rls" "${D}/usr/bin/rls-${PV}" || die
	fi
	if use rustfmt; then
		mv "${D}/usr/bin/cargo-fmt" "${D}/usr/bin/cargo-fmt-${PV}" || die
		mv "${D}/usr/bin/rustfmt" "${D}/usr/bin/rustfmt-${PV}" || die
	fi

	if use doc; then
		dodir "/usr/share/doc/${P}"
		mv "${D}/usr/share/doc/rust"/* "${D}/usr/share/doc/${P}" || die
		rmdir "${D}/usr/share/doc/rust" || die
	fi

	dodoc COPYRIGHT
	rm "${D}/usr/share/doc/${P}/LICENSE-APACHE" || die
	rm "${D}/usr/share/doc/${P}/LICENSE-MIT" || die

	docompress "/usr/share/${P}/man"

	cat <<-EOF > "${T}"/50${P}
		LDPATH="/usr/lib/rustlib/${CHOST}/lib"
		MANPATH="/usr/share/${P}/man"
	EOF
	doenvd "${T}"/50${P}

	cat <<-EOF > "${T}/provider-${P}"
		/usr/bin/rustdoc
		/usr/bin/rust-gdb
		/usr/bin/rust-lldb
	EOF
	if use cargo; then
	    echo /usr/bin/cargo >> "${T}/provider-${P}"
	fi
	if use clippy; then
	    echo /usr/bin/cargo-clippy >> "${T}/provider-${P}"
	    echo /usr/bin/clippy-driver >> "${T}/provider-${P}"
	fi
	if use rls; then
	    echo /usr/bin/rls >> "${T}/provider-${P}"
	fi
	if use rustfmt; then
	    echo /usr/bin/cargo-fmt >> "${T}/provider-${P}"
	    echo /usr/bin/rustfmt >> "${T}/provider-${P}"
	fi
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
