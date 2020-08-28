# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{6,7,8} )

inherit bash-completion-r1 check-reqs estack flag-o-matic llvm multilib-build multiprocessing python-any-r1 rust-toolchain toolchain-funcs

ABI_VER="$(ver_cut 1-2)"
SLOT="stable/${ABI_VER}"
MY_P="rustc-${PV}"
SRC="${MY_P}-src.tar.xz"
KEYWORDS="amd64 ~arm ~arm64 ~ppc ppc64 x86"

RUST_STAGE0_VERSION="1.$(($(ver_cut 2) - 1)).2"
RUST_TOOLCHAIN_BASEURL="https://portage.smaeul.xyz/distfiles/"

DESCRIPTION="Systems programming language from Mozilla"
HOMEPAGE="https://www.rust-lang.org/"

SRC_URI="
	https://static.rust-lang.org/dist/${SRC} -> rustc-${PV}-src.tar.xz
	!system-bootstrap? (
		amd64? ( $(rust_arch_uri x86_64-gentoo-linux-musl        rust-${RUST_STAGE0_VERSION} ) )
		arm?   ( $(rust_arch_uri armv7a-unknown-linux-musleabihf rust-${RUST_STAGE0_VERSION} ) )
		arm64? ( $(rust_arch_uri aarch64-gentoo-linux-musl       rust-${RUST_STAGE0_VERSION} ) )
		ppc?   ( $(rust_arch_uri powerpc-gentoo-linux-musl       rust-${RUST_STAGE0_VERSION} ) )
		ppc64? ( $(rust_arch_uri powerpc64-gentoo-linux-musl     rust-${RUST_STAGE0_VERSION} ) )
		x86?   ( $(rust_arch_uri i686-gentoo-linux-musl          rust-${RUST_STAGE0_VERSION} ) )
	)
"

ALL_LLVM_TARGETS=( AArch64 AMDGPU ARM BPF Hexagon Lanai Mips MSP430
	NVPTX PowerPC RISCV Sparc SystemZ WebAssembly X86 XCore )
ALL_LLVM_TARGETS=( "${ALL_LLVM_TARGETS[@]/#/llvm_targets_}" )
LLVM_TARGET_USEDEPS=${ALL_LLVM_TARGETS[@]/%/?}

LICENSE="|| ( MIT Apache-2.0 ) BSD-1 BSD-2 BSD-4 UoI-NCSA"

IUSE="clippy cpu_flags_arm_neon cpu_flags_arm_thumb2 cpu_flags_x86_sse2 debug doc libressl miri nightly parallel-compiler rls rustfmt system-bootstrap system-llvm wasm ${ALL_LLVM_TARGETS[*]}"

# Please keep the LLVM dependency block separate. Since LLVM is slotted,
# we need to *really* make sure we're not pulling more than one slot
# simultaneously.

# How to use it:
# 1. List all the working slots (with min versions) in ||, newest first.
# 2. Update the := to specify *max* version, e.g. < 11.
# 3. Specify LLVM_MAX_SLOT, e.g. 10.
LLVM_DEPEND="
	|| (
		sys-devel/llvm:9[${LLVM_TARGET_USEDEPS// /,}]
		sys-devel/llvm:10[${LLVM_TARGET_USEDEPS// /,}]
	)
	<sys-devel/llvm-11:=
"
LLVM_MAX_SLOT=10

BOOTSTRAP_DEPEND="|| ( >=dev-lang/rust-1.$(($(ver_cut 2) - 1)) >=dev-lang/rust-bin-1.$(($(ver_cut 2) - 1)) )"

BDEPEND="
	${PYTHON_DEPS}
	app-eselect/eselect-rust
	|| (
		>=sys-devel/gcc-4.7
		>=sys-devel/clang-3.5
	)
	system-bootstrap? ( ${BOOTSTRAP_DEPEND}	)
	!system-llvm? (
		dev-util/cmake
		dev-util/ninja
	)
"

# libgit2 should be at least same as bundled into libgit-sys #707746
DEPEND="
	>=dev-libs/libgit2-0.99:=
	net-libs/libssh2:=
	net-libs/http-parser:=
	net-misc/curl:=[http2,ssl]
	sys-libs/libssp_nonshared:=[${MULTILIB_USEDEP}]
	sys-libs/zlib:=
	!libressl? ( dev-libs/openssl:0= )
	libressl? ( dev-libs/libressl:0= )
	system-llvm? (
		${LLVM_DEPEND}
		wasm? ( sys-devel/lld )
	)
"

RDEPEND="${DEPEND}
	app-eselect/eselect-rust
"

REQUIRED_USE="|| ( ${ALL_LLVM_TARGETS[*]} )
	miri? ( nightly )
	parallel-compiler? ( nightly )
	wasm? ( llvm_targets_WebAssembly )
	x86? ( cpu_flags_x86_sse2 )
"

QA_FLAGS_IGNORED="
	usr/bin/.*-${PV}
	usr/lib/${P}/rustlib/.*/bin/.*
	usr/lib/${P}/rustlib/.*/lib/lib.*.so.*
"

QA_SONAME="
	usr/lib/${P}/rustlib/.*/lib/lib.*.so.*
"

PATCHES=(
	"${FILESDIR}"/0001-Don-t-pass-CFLAGS-to-the-C-compiler.patch
	"${FILESDIR}"/0002-Fix-LLVM-build.patch
	"${FILESDIR}"/0003-Fix-rustdoc-when-cross-compiling-on-musl.patch
	"${FILESDIR}"/0004-Use-static-native-libraries-when-linking-static-exec.patch
	"${FILESDIR}"/0005-Remove-musl_root-and-CRT-fallback-from-musl-targets.patch
	"${FILESDIR}"/0006-Prefer-libgcc_eh-over-libunwind-for-musl.patch
	"${FILESDIR}"/0007-Link-libssp_nonshared.a-on-all-musl-targets.patch
	"${FILESDIR}"/0008-test-failed-doctest-output-Fix-normalization.patch
	"${FILESDIR}"/0009-test-sysroot-crates-are-unstable-Fix-test-when-rpath.patch
	"${FILESDIR}"/0010-test-use-extern-for-plugins-Don-t-assume-multilib.patch
	"${FILESDIR}"/0011-Ignore-broken-and-non-applicable-tests.patch
	"${FILESDIR}"/0012-Link-stage-2-tools-dynamically-to-libstd.patch
	"${FILESDIR}"/0013-Move-debugger-scripts-to-usr-share-rust.patch
	"${FILESDIR}"/0014-Add-gentoo-target-specs.patch
	"${FILESDIR}"/0030-libc-linkage.patch
	"${FILESDIR}"/0031-libressl.patch
	"${FILESDIR}"/0040-rls-atomics.patch
	"${FILESDIR}"/0050-llvm.patch
	"${FILESDIR}"/0051-llvm-powerpc-elfv2.patch
)

S="${WORKDIR}/${MY_P}-src"

toml_usex() {
	usex "$1" true false
}

pre_build_checks() {
	local M=6144
	M=$(( $(usex clippy 128 0) + ${M} ))
	M=$(( $(usex miri 128 0) + ${M} ))
	M=$(( $(usex rls 512 0) + ${M} ))
	M=$(( $(usex rustfmt 256 0) + ${M} ))
	M=$(( $(usex system-llvm 0 2048) + ${M} ))
	M=$(( $(usex wasm 256 0) + ${M} ))
	M=$(( $(usex debug 15 10) * ${M} / 10 ))
	eshopts_push -s extglob
	if is-flagq '-g?(gdb)?([1-9])'; then
		M=$(( 15 * ${M} / 10 ))
	fi
	eshopts_pop
	M=$(( $(usex system-bootstrap 0 1024) + ${M} ))
	M=$(( $(usex doc 256 0) + ${M} ))
	CHECKREQS_DISK_BUILD=${M}M check-reqs_pkg_${EBUILD_PHASE}
}

pkg_pretend() {
	pre_build_checks
}

pkg_setup() {
	pre_build_checks
	python-any-r1_pkg_setup

	# required to link agains system libs, otherwise
	# crates use bundled sources and compile own static version
	export LIBGIT2_SYS_USE_PKG_CONFIG=1
	export LIBSSH2_SYS_USE_PKG_CONFIG=1
	export PKG_CONFIG_ALLOW_CROSS=1

	if use system-llvm; then
		llvm_pkg_setup

		local llvm_config="$(get_llvm_prefix "$LLVM_MAX_SLOT")/bin/llvm-config"

		export LLVM_LINK_SHARED=1
		export RUSTFLAGS="${RUSTFLAGS} -Lnative=$("${llvm_config}" --libdir)"
	fi
}

src_prepare() {
	if ! use system-bootstrap; then
		local rust_stage0_root="${WORKDIR}"/rust-stage0
		local rust_stage0="rust-${RUST_STAGE0_VERSION}-${CHOST}"

		"${WORKDIR}/${rust_stage0}"/install.sh --disable-ldconfig \
			--components=rust-std-${CHOST},rustc,cargo \
			--destdir="${rust_stage0_root}" --prefix=/ || die
	fi

	default
}

src_configure() {
	local arch_cflags rust_target="" rust_targets="\"$CHOST\"" tools="\"cargo\""

	# Collect rust target names to compile standard libs for all ABIs.
	for v in $(multilib_get_enabled_abi_pairs); do
		rust_target=$(rust_abi $(get_abi_CHOST ${v##*.}) | sed s/gnu/musl/)
		rust_targets="${rust_targets},\"${rust_target}\""

		if [ "$rust_target" = "armv7-unknown-linux-musleabihf" ] &&
		   use cpu_flags_arm_neon && use cpu_flags_arm_thumb2; then
			rust_targets="${rust_targets},\"thumbv7neon-unknown-linux-musleabihf\""
		fi
	done
	if use wasm; then
		rust_targets="${rust_targets},\"wasm32-unknown-unknown\""
		if use system-llvm; then
			# un-hardcode rust-lld linker for this target
			# https://bugs.gentoo.org/715348
			sed -i '/linker:/ s/rust-lld/wasm-ld/' src/librustc_target/spec/wasm32_base.rs || die
		fi
	fi

	if use clippy; then
		tools="\"clippy\",$tools"
	fi
	if use miri; then
		tools="\"miri\",$tools"
	fi
	if use rls; then
		tools="\"rls\",\"analysis\",\"src\",$tools"
	fi
	if use rustfmt; then
		tools="\"rustfmt\",$tools"
	fi

	local rust_stage0_root
	if use system-bootstrap; then
		rust_stage0_root="$(rustc --print sysroot)"
	else
		rust_stage0_root="${WORKDIR}"/rust-stage0
	fi

	cat <<- EOF > "${S}"/config.toml
		[llvm]
		optimize = $(toml_usex !debug)
		release-debuginfo = $(toml_usex debug)
		assertions = $(toml_usex debug)
		ninja = true
		targets = "${LLVM_TARGETS// /;}"
		experimental-targets = ""
		link-shared = $(toml_usex system-llvm)
		[build]
		build = "${CHOST}"
		host = ["${CHOST}"]
		target = [${rust_targets}]
		cargo = "${rust_stage0_root}/bin/cargo"
		rustc = "${rust_stage0_root}/bin/rustc"
		docs = $(toml_usex doc)
		compiler-docs = $(toml_usex doc)
		submodules = false
		python = "${EPYTHON}"
		locked-deps = true
		vendor = true
		extended = true
		tools = [${tools}]
		verbose = 2
		sanitizers = false
		profiler = false
		cargo-native-static = false
		[install]
		prefix = "${EPREFIX}/usr"
		libdir = "lib/${P}"
		docdir = "share/doc/${PF}"
		mandir = "share/${P}/man"
		[rust]
		optimize = true
		debug = $(toml_usex debug)
		debug-assertions = $(toml_usex debug)
		debuginfo-level-rustc = 0
		backtrace = true
		incremental = false
		default-linker = "$(tc-getCC)"
		parallel-compiler = $(toml_usex parallel-compiler)
		channel = "$(usex nightly nightly stable)"
		rpath = false
		verbose-tests = true
		optimize-tests = $(toml_usex !debug)
		codegen-tests = true
		dist-src = false
		remap-debuginfo = true
		lld = $(usex system-llvm false $(toml_usex wasm))
		backtrace-on-ice = true
		jemalloc = false
		[dist]
		src-tarball = false
		[target.${CHOST}]
		cc = "$(tc-getCC)"
		cxx = "$(tc-getCXX)"
		linker = "$(tc-getCC)"
		ar = "$(tc-getAR)"
		crt-static = false
	EOF
	if use system-llvm; then
		cat <<- EOF >> "${S}"/config.toml
			llvm-config = "$(get_llvm_prefix "${LLVM_MAX_SLOT}")/bin/llvm-config"
		EOF
	fi

	for v in $(multilib_get_enabled_abi_pairs); do
		rust_target=$(rust_abi $(get_abi_CHOST ${v##*.}) | sed s/gnu/musl/)
		arch_cflags="$(get_abi_CFLAGS ${v##*.})"

		export "CFLAGS_${rust_target//-/_}"="$CFLAGS ${arch_cflags}"

		cat <<- EOF >> "${S}"/config.toml
			[target.${rust_target}]
			cc = "$(tc-getCC)"
			cxx = "$(tc-getCXX)"
			linker = "$(tc-getCC)"
			ar = "$(tc-getAR)"
			crt-static = false
		EOF

		if [ "$rust_target" = "armv7-unknown-linux-musleabihf" ] &&
		   use cpu_flags_arm_neon && use cpu_flags_arm_thumb2; then
			rust_target=thumbv7neon-unknown-linux-musleabihf

			export "CFLAGS_${rust_target//-/_}"="$CFLAGS ${arch_cflags}"

			cat <<- EOF >> "${S}"/config.toml
				[target.${rust_target}]
				cc = "$(tc-getCC)"
				cxx = "$(tc-getCXX)"
				linker = "$(tc-getCC)"
				ar = "$(tc-getAR)"
				crt-static = false
			EOF
		fi
	done

	if use wasm; then
		cat <<- EOF >> "${S}"/config.toml
			[target.wasm32-unknown-unknown]
			linker = "$(usex system-llvm lld rust-lld)"
		EOF
	fi

	einfo "Rust configured with the following settings:"
	cat "${S}"/config.toml || die
}

src_compile() {
	RUST_BACKTRACE=1 \
	"${EPYTHON}" ./x.py build -vv --config="${S}"/config.toml -j$(makeopts_jobs) || die
}

src_test() {
	RUST_BACKTRACE=1 \
	"${EPYTHON}" ./x.py test -vv --config="${S}"/config.toml -j$(makeopts_jobs) --no-doc --no-fail-fast \
		src/test/codegen \
		src/test/codegen-units \
		src/test/compile-fail \
		src/test/incremental \
		src/test/mir-opt \
		src/test/pretty \
		src/test/run-fail \
		src/test/run-make \
		src/test/run-make-fulldeps \
		src/test/rustdoc \
		src/test/rustdoc-js \
		src/test/rustdoc-js-std \
		src/test/rustdoc-ui \
		src/test/ui \
		src/test/ui-fulldeps || die
}

src_install() {
	DESTDIR="${D}" \
	"${EPYTHON}" ./x.py install -vv --config="${S}"/config.toml || die

	# bug #689562, #689160
	rm "${D}/etc/bash_completion.d/cargo" || die
	rmdir "${D}"/etc{/bash_completion.d,} || die
	dobashcomp build/tmp/dist/cargo-image/etc/bash_completion.d/cargo

	mv "${ED}/usr/bin/cargo" "${ED}/usr/bin/cargo-${PV}" || die
	mv "${ED}/usr/bin/rustc" "${ED}/usr/bin/rustc-${PV}" || die
	mv "${ED}/usr/bin/rustdoc" "${ED}/usr/bin/rustdoc-${PV}" || die
	mv "${ED}/usr/bin/rust-gdb" "${ED}/usr/bin/rust-gdb-${PV}" || die
	mv "${ED}/usr/bin/rust-gdbgui" "${ED}/usr/bin/rust-gdbgui-${PV}" || die
	mv "${ED}/usr/bin/rust-lldb" "${ED}/usr/bin/rust-lldb-${PV}" || die

	if use clippy; then
		mv "${ED}/usr/bin/clippy-driver" "${ED}/usr/bin/clippy-driver-${PV}" || die
		mv "${ED}/usr/bin/cargo-clippy" "${ED}/usr/bin/cargo-clippy-${PV}" || die
	fi
	if use miri; then
		mv "${ED}/usr/bin/miri" "${ED}/usr/bin/miri-${PV}" || die
		mv "${ED}/usr/bin/cargo-miri" "${ED}/usr/bin/cargo-miri-${PV}" || die
	fi
	if use rls; then
		mv "${ED}/usr/bin/rls" "${ED}/usr/bin/rls-${PV}" || die
	fi
	if use rustfmt; then
		mv "${ED}/usr/bin/rustfmt" "${ED}/usr/bin/rustfmt-${PV}" || die
		mv "${ED}/usr/bin/cargo-fmt" "${ED}/usr/bin/cargo-fmt-${PV}" || die
	fi

	# Move public shared libs to abi specific libdir
	mv "${ED}/usr/lib/${P}"/*.so "${ED}/usr/lib/${P}/rustlib/${CHOST}/lib" || die

	# versioned libdir/mandir support
	newenvd - "50${P}" <<-_EOF_
		LDPATH="${EPREFIX}/usr/lib/${P}/rustlib/${CHOST}/lib"
		MANPATH="${EPREFIX}/usr/share/${P}/man"
	_EOF_

	rm "${ED}/usr/lib/${P}/rustlib/components" || die
	rm "${ED}/usr/lib/${P}/rustlib/install.log" || die
	rm "${ED}/usr/lib/${P}/rustlib"/manifest-* || die
	rm "${ED}/usr/lib/${P}/rustlib/rust-installer-version" || die
	rm "${ED}/usr/lib/${P}/rustlib/uninstall.sh" || die

	dodoc COPYRIGHT
	rm "${ED}/usr/share/doc/${P}"/*.old || die
	rm "${ED}/usr/share/doc/${P}/LICENSE-APACHE" || die
	rm "${ED}/usr/share/doc/${P}/LICENSE-MIT" || die

	# note: eselect-rust adds EROOT to all paths below
	cat <<-EOF > "${T}/provider-${P}"
		/usr/bin/cargo
		/usr/bin/rustdoc
		/usr/bin/rust-gdb
		/usr/bin/rust-gdbgui
		/usr/bin/rust-lldb
	EOF
	if use clippy; then
		echo /usr/bin/clippy-driver >> "${T}/provider-${P}"
		echo /usr/bin/cargo-clippy >> "${T}/provider-${P}"
	fi
	if use miri; then
		echo /usr/bin/miri >> "${T}/provider-${P}"
		echo /usr/bin/cargo-miri >> "${T}/provider-${P}"
	fi
	if use rls; then
		echo /usr/bin/rls >> "${T}/provider-${P}"
	fi
	if use rustfmt; then
		echo /usr/bin/rustfmt >> "${T}/provider-${P}"
		echo /usr/bin/cargo-fmt >> "${T}/provider-${P}"
	fi

	insinto /etc/env.d/rust
	doins "${T}/provider-${P}"
}

pkg_postinst() {
	eselect rust update --if-unset

	elog "Rust installs a helper script for calling GDB and LLDB,"
	elog "for your convenience it is installed under /usr/bin/rust-{gdb,lldb}-${PV}."

	if has_version app-editors/emacs; then
		elog "install app-emacs/rust-mode to get emacs support for rust."
	fi

	if has_version app-editors/gvim || has_version app-editors/vim; then
		elog "install app-vim/rust-vim to get vim support for rust."
	fi
}

pkg_postrm() {
	eselect rust cleanup
}
