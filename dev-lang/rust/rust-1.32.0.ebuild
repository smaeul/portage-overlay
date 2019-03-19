# Copyright 1999-2018 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=6

PYTHON_COMPAT=( python{2_7,3_{5,6,7}} )
LLVM_MAX_SLOT=8

inherit eapi7-ver llvm multiprocessing python-any-r1 toolchain-funcs

ABI_VER="$(ver_cut 1-2)"
SLOT="stable/${ABI_VER}"
MY_P="rustc-${PV}"
SRC="${MY_P}-src.tar.xz"
KEYWORDS="~amd64 ~arm ~arm64 ~ppc64 ~x86"

RUST_STAGE0_VERSION="1.$(($(ver_cut 2) - 1)).1"

DESCRIPTION="Systems programming language from Mozilla"
HOMEPAGE="https://www.rust-lang.org/"

SRC_URI="https://static.rust-lang.org/dist/${SRC} -> rustc-${PV}-src.tar.xz
	amd64? ( https://portage.smaeul.xyz/distfiles/rust-${RUST_STAGE0_VERSION}-x86_64-gentoo-linux-musl.tar.xz )
	arm? ( https://portage.smaeul.xyz/distfiles/rust-${RUST_STAGE0_VERSION}-armv7a-unknown-linux-musleabihf.tar.xz )
	arm64? ( https://portage.smaeul.xyz/distfiles/rust-${RUST_STAGE0_VERSION}-aarch64-gentoo-linux-musl.tar.xz )
	ppc64? ( https://portage.smaeul.xyz/distfiles/rust-${RUST_STAGE0_VERSION}-powerpc64-gentoo-linux-musl.tar.xz )
	x86? ( https://portage.smaeul.xyz/distfiles/rust-${RUST_STAGE0_VERSION}-i686-gentoo-linux-musl.tar.xz )
"

ALL_LLVM_TARGETS=( AArch64 AMDGPU ARM BPF Hexagon Lanai Mips MSP430
	NVPTX PowerPC Sparc SystemZ X86 XCore )
ALL_LLVM_TARGETS=( "${ALL_LLVM_TARGETS[@]/#/llvm_targets_}" )
LLVM_TARGET_USEDEPS=${ALL_LLVM_TARGETS[@]/%/?}

LICENSE="|| ( MIT Apache-2.0 ) BSD-1 BSD-2 BSD-4 UoI-NCSA"

IUSE="clippy cpu_flags_x86_sse2 debug doc libressl rls rustfmt system-llvm ${ALL_LLVM_TARGETS[*]}"

COMMON_DEPEND=">=app-eselect/eselect-rust-0.3_pre20150425
		!libressl? ( dev-libs/openssl:0= )
		libressl? ( dev-libs/libressl:0= )
		net-libs/http-parser:=
		net-libs/libssh2:=
		net-misc/curl:=[ssl]
		sys-libs/zlib:=
		system-llvm? ( >=sys-devel/llvm-7:=[${LLVM_TARGET_USEDEPS// /,}] )"
DEPEND="${COMMON_DEPEND}
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
RDEPEND="${COMMON_DEPEND}
	!dev-util/cargo
	rustfmt? ( !dev-util/rustfmt )"

REQUIRED_USE="|| ( ${ALL_LLVM_TARGETS[*]} )
	x86? ( cpu_flags_x86_sse2 )"

PATCHES=(
	"${FILESDIR}/1.32.0-system-llvm-7-SIGSEGV.patch"
	"${FILESDIR}/0001-Don-t-pass-CFLAGS-to-the-C-compiler.patch"
	"${FILESDIR}/0002-Fix-LLVM-build.patch"
	"${FILESDIR}/0003-Allow-rustdoc-to-work-when-cross-compiling-on-musl.patch"
	"${FILESDIR}/0004-Require-static-native-libraries-when-linking-static-.patch"
	"${FILESDIR}/0005-Remove-nostdlib-and-musl_root-from-musl-targets.patch"
	"${FILESDIR}/0006-Prefer-libgcc_eh-over-libunwind-for-musl.patch"
	"${FILESDIR}/0007-rustc_data_structures-use-libc-types-constants-in-fl.patch"
	"${FILESDIR}/0008-runtest-Fix-proc-macro-tests-on-musl-hosts.patch"
	"${FILESDIR}/0009-test-target-feature-gate-Only-run-on-relevant-target.patch"
	"${FILESDIR}/0010-test-use-extern-for-plugins-Don-t-assume-multilib.patch"
	"${FILESDIR}/0011-test-sysroot-crates-are-unstable-Fix-test-when-rpath.patch"
	"${FILESDIR}/0012-Ignore-broken-and-non-applicable-tests.patch"
	"${FILESDIR}/0013-Link-stage-2-tools-dynamically-to-libstd.patch"
	"${FILESDIR}/0014-Move-debugger-scripts-to-usr-share-rust.patch"
	"${FILESDIR}/0015-Add-gentoo-target-specs.patch"
	"${FILESDIR}/0030-liblibc-linkage.patch"
	"${FILESDIR}/0031-liblibc-1b130d4c349d.patch"
	"${FILESDIR}/0040-rls-atomics.patch"
	"${FILESDIR}/0050-llvm.patch"
	"${FILESDIR}/0051-llvm-D45520.patch"
	"${FILESDIR}/0052-llvm-D52013.patch"
	"${FILESDIR}/0053-llvm-secureplt.patch"
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
		--components=rust-std-$CHOST,rustc,cargo \
		--disable-ldconfig \
		|| die
}

src_configure() {
	local tools='"cargo"'

	for tool in clippy rls rustfmt; do
		if use $tool; then
			tools+=", \"$tool\""
		fi
	done

	cat <<- EOF > "${S}"/config.toml
		[llvm]
		ninja = true
		optimize = $(toml_usex !debug)
		release-debuginfo = $(toml_usex debug)
		assertions = $(toml_usex debug)
		targets = "${LLVM_TARGETS// /;}"
		link-shared = $(toml_usex system-llvm)
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
		extended = true
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
		default-linker = "$(tc-getCC)"
		channel = "stable"
		rpath = false
		optimize-tests = $(toml_usex !debug)
		dist-src = false
		jemalloc = false
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
	"${EPYTHON}" x.py build --config="${S}"/config.toml -j$(makeopts_jobs) --exclude src/tools/miri || die
}

src_test() {
	"${EPYTHON}" x.py test -j$(makeopts_jobs) --no-doc --no-fail-fast \
		src/test/codegen \
		src/test/codegen-units \
		src/test/compile-fail \
		src/test/compile-fail-fulldeps \
		src/test/incremental \
		src/test/mir-opt \
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
		src/test/ui-fulldeps || die
}

src_install() {
	env DESTDIR="${D}" "${EPYTHON}" x.py install || die

	mv "${D}/usr/bin/cargo" "${D}/usr/bin/cargo-${PV}" || die
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
	rm "${D}/usr/share/doc/${P}"/*.old || die
	rm "${D}/usr/share/doc/${P}/LICENSE-APACHE" || die
	rm "${D}/usr/share/doc/${P}/LICENSE-MIT" || die

	docompress "/usr/share/${P}/man"

	cat <<-EOF > "${T}"/50${P}
		LDPATH="/usr/lib/rustlib/${CHOST}/lib"
		MANPATH="/usr/share/${P}/man"
	EOF
	doenvd "${T}"/50${P}

	cat <<-EOF > "${T}/provider-${P}"
		/usr/bin/cargo
		/usr/bin/rustdoc
		/usr/bin/rust-gdb
		/usr/bin/rust-lldb
	EOF
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

	ewarn "cargo is now installed from dev-lang/rust{,-bin} instead of dev-util/cargo."
	ewarn "This might have resulted in a dangling symlink for /usr/bin/cargo on some"
	ewarn "systems. This can be resolved by calling 'sudo eselect rust set ${P}'."

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
