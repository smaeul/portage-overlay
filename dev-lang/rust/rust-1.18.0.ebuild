# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

PYTHON_COMPAT=( python2_7 )

inherit python-any-r1 versionator toolchain-funcs

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
STAGE0_VERSION="1.$(($(get_version_component_range 2) - 0)).0"
RUST_STAGE0="rust-${STAGE0_VERSION}-${CTARGET}"

DESCRIPTION="Systems programming language from Mozilla"
HOMEPAGE="https://www.rust-lang.org/"

SRC_URI="https://static.rust-lang.org/dist/${SRC} -> rustc-${PV}-src.tar.gz
	http://portage.smaeul.xyz/distfiles/${RUST_STAGE0}.tar.gz
"

LICENSE="|| ( MIT Apache-2.0 ) BSD-1 BSD-2 BSD-4 UoI-NCSA"

IUSE="clang debug doc libcxx +system-llvm"
REQUIRED_USE="libcxx? ( clang )"

RDEPEND="libcxx? ( sys-libs/libcxx )
	system-llvm? ( sys-devel/llvm:= )
"

DEPEND="${RDEPEND}
	${PYTHON_DEPS}
	>=dev-lang/perl-5.0
	clang? ( sys-devel/clang )
"

PDEPEND=">=app-eselect/eselect-rust-0.3_pre20150425
	dev-util/cargo
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

src_prepare() {
	default

	"${WORKDIR}/${RUST_STAGE0}/install.sh" \
		--prefix="${WORKDIR}/stage0" \
		--components=rust-std-${CTARGET},rustc,cargo \
		--disable-ldconfig \
		|| die
}

src_configure() {
	export CFG_DISABLE_LDCONFIG="notempty"
	export LLVM_LINK_SHARED=1

	"${ECONF_SOURCE:-.}"/configure \
		--build=${CTARGET} \
		--host=${CTARGET} \
		--prefix="${EPREFIX}/usr" \
		--libdir="${EPREFIX}/usr/$(get_libdir)/${P}" \
		--mandir="${EPREFIX}/usr/share/${P}/man" \
		--release-channel=${SLOT%%/*} \
		--disable-manage-submodules \
		--default-linker=$(tc-getBUILD_CC) \
		--default-ar=$(tc-getBUILD_AR) \
		--python=${EPYTHON} \
		--disable-rpath \
		--enable-local-rust \
		--enable-vendor \
		--local-rust-root="${WORKDIR}/stage0" \
		$(use_enable clang) \
		$(use_enable debug) \
		$(use_enable debug llvm-assertions) \
		$(use_enable !debug optimize) \
		$(use_enable !debug optimize-cxx) \
		$(use_enable !debug optimize-llvm) \
		$(use_enable !debug optimize-tests) \
		$(use_enable doc docs) \
		$(use_enable libcxx libcpp) \
		$(usex system-llvm "--llvm-root=${EPREFIX}$(llvm-config --prefix)" " ") \
		|| die
}

src_install() {
	unset SUDO_USER

	default

	rm "${D}/usr/lib/rust-${PV}/rustlib/components" || die
	rm "${D}/usr/lib/rust-${PV}/rustlib/install.log" || die
	rm "${D}/usr/lib/rust-${PV}/rustlib/manifest-rust-std-x86_64-unknown-linux-musl" || die
	rm "${D}/usr/lib/rust-${PV}/rustlib/manifest-rustc" || die
	rm "${D}/usr/lib/rust-${PV}/rustlib/rust-installer-version" || die
	rm "${D}/usr/lib/rust-${PV}/rustlib/uninstall.sh" || die

	mv "${D}/usr/bin/rustc" "${D}/usr/bin/rustc-${PV}" || die
	mv "${D}/usr/bin/rustdoc" "${D}/usr/bin/rustdoc-${PV}" || die
	mv "${D}/usr/bin/rust-gdb" "${D}/usr/bin/rust-gdb-${PV}" || die
	mv "${D}/usr/bin/rust-lldb" "${D}/usr/bin/rust-lldb-${PV}" || die

	dodoc COPYRIGHT

	dodir "/usr/share/doc/rust-${PV}/"
	mv "${D}/usr/share/doc/rust"/* "${D}/usr/share/doc/rust-${PV}/" || die
	rmdir "${D}/usr/share/doc/rust/" || die

	cat <<-EOF > "${T}"/50${P}
	LDPATH="/usr/$(get_libdir)/${P}"
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
