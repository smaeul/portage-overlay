# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

# Generate with
# sed 's/^"checksum \([[:graph:]]\+\) \([[:graph:]]\+\) (.*$/\1-\2/' Cargo.lock
CRATES="
advapi32-sys-0.2.0
aho-corasick-0.5.3
aho-corasick-0.6.3
atty-0.2.2
backtrace-0.3.2
backtrace-sys-0.1.11
bitflags-0.9.1
bufstream-0.1.3
cfg-if-0.1.2
cmake-0.1.24
crossbeam-0.2.10
curl-0.4.7
curl-sys-0.3.14
dbghelp-sys-0.2.0
docopt-0.8.1
dtoa-0.4.1
env_logger-0.4.3
error-chain-0.11.0-rc.2
filetime-0.1.10
flate2-0.2.19
foreign-types-0.2.0
fs2-0.4.2
gcc-0.3.51
git2-0.6.6
git2-curl-0.7.0
glob-0.2.11
hamcrest-0.1.1
hex-0.2.0
idna-0.1.2
itoa-0.3.1
jobserver-0.1.6
kernel32-sys-0.2.2
lazy_static-0.2.8
libc-0.2.25
libgit2-sys-0.6.12
libssh2-sys-0.2.6
libz-sys-1.0.16
log-0.3.8
matches-0.1.6
memchr-0.1.11
memchr-1.0.1
miniz-sys-0.1.9
miow-0.2.1
net2-0.2.29
num-0.1.39
num-bigint-0.1.39
num-complex-0.1.38
num-integer-0.1.34
num-iter-0.1.33
num-rational-0.1.38
num-traits-0.1.39
num_cpus-1.6.2
openssl-0.9.14
openssl-probe-0.1.1
openssl-sys-0.9.14
openssl-sys-0.9.15
percent-encoding-1.0.0
pkg-config-0.3.9
psapi-sys-0.1.0
quote-0.3.15
rand-0.3.15
regex-0.1.80
regex-0.2.2
regex-syntax-0.3.9
regex-syntax-0.4.1
rustc-demangle-0.1.4
rustc-serialize-0.3.24
scoped-tls-0.1.0
semver-0.7.0
semver-parser-0.7.0
serde-1.0.9
serde_derive-1.0.9
serde_derive_internals-0.15.1
serde_ignored-0.0.3
serde_json-1.0.2
shell-escape-0.1.3
socket2-0.2.1
strsim-0.6.0
syn-0.11.11
synom-0.11.3
tar-0.4.13
tempdir-0.3.5
termcolor-0.3.2
thread-id-2.0.0
thread_local-0.2.7
thread_local-0.3.4
toml-0.4.2
unicode-bidi-0.3.4
unicode-normalization-0.1.5
unicode-xid-0.0.4
unreachable-1.0.0
url-1.5.1
utf8-ranges-0.1.3
utf8-ranges-1.0.0
vcpkg-0.2.2
void-1.0.2
winapi-0.2.8
winapi-build-0.1.1
wincolor-0.1.4
ws2_32-sys-0.2.1
"

inherit bash-completion-r1 cargo versionator

CARGO_SNAPSHOT_VERSION="0.$(($(get_version_component_range 2) - 1)).0"
CTARGET=${CHOST/gentoo/unknown}

DESCRIPTION="The Rust's package manager"
HOMEPAGE="http://crates.io"
SRC_URI="https://github.com/rust-lang/cargo/archive/${PV}.tar.gz -> ${P}.tar.gz
	http://portage.smaeul.xyz/distfiles/cargo-${CARGO_SNAPSHOT_VERSION}-${CTARGET}.tar.xz
	$(cargo_crate_uris ${CRATES})"

RESTRICT="mirror"
LICENSE="|| ( MIT Apache-2.0 )"
SLOT="0"
KEYWORDS="~amd64 ~x86"

IUSE="bash-completion doc libressl static"

DEPEND="
    static? (
		libressl? ( <dev-libs/libressl-2.6.1[static-libs] )
		!libressl? ( dev-libs/openssl[static-libs] )
		net-libs/http-parser[static-libs]
        net-libs/libssh2[static-libs]
        net-misc/curl[ssl,static-libs]
		sys-libs/zlib[static-libs]
    )
    !static? (
		libressl? ( <dev-libs/libressl-2.6.1 )
		!libressl? ( dev-libs/openssl )
		net-libs/http-parser
        net-libs/libssh2
        net-misc/curl[ssl]
		sys-libs/zlib
    )
	dev-util/cmake
	sys-apps/coreutils
	sys-apps/diffutils
	sys-apps/findutils
	sys-apps/sed
	>=virtual/rust-1.9.0
"
RDEPEND="
	!dev-util/cargo-bin
    !static? (
		libressl? ( <dev-libs/libressl-2.6.1:0= )
		!libressl? ( dev-libs/openssl:0= )
		net-libs/http-parser:=
        net-libs/libssh2:=
        net-misc/curl:=[ssl]
		sys-libs/zlib:=
    )
"

src_prepare() {
	default

	# libressl needs a newer version of openssl-sys
	use libressl && rm Cargo.lock
}

src_compile() {
	export CARGO_HOME="${ECARGO_HOME}"
	local cargo="${WORKDIR}/cargo-${CARGO_SNAPSHOT_VERSION}-${CTARGET}/cargo/bin/cargo"
	${cargo} build --release || die

	# Build HTML documentation
	use doc && ${cargo} doc
}

src_install() {
	dobin target/release/cargo

	# Install HTML documentation
	use doc && HTML_DOCS=("target/doc")
	einstalldocs

	use bash-completion && newbashcomp src/etc/cargo.bashcomp.sh cargo
	insinto /usr/share/zsh/site-functions
	doins src/etc/_cargo
	doman src/etc/man/*
}
