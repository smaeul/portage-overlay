# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI="5"

inherit eutils flag-o-matic linux-info toolchain-funcs versionator

DESCRIPTION="Misc tools bundled with kernel sources"
HOMEPAGE="https://kernel.org/"

LINUX_V="${PV:0:1}.x"
if [[ ${PV} == *_rc* ]] ; then
	LINUX_VER=$(get_version_component_range 1-2).$(($(get_version_component_range 3)-1))
	PATCH_VERSION=$(get_version_component_range 1-3)
	LINUX_PATCH=patch-${PV//_/-}.xz
	SRC_URI="mirror://kernel/linux/kernel/v${LINUX_V}/testing/${LINUX_PATCH}
		mirror://kernel/linux/kernel/v${LINUX_V}/testing/v${PATCH_VERSION}/${LINUX_PATCH}"
else
	VER_COUNT=$(get_version_component_count)
	if [[ ${VER_COUNT} -gt 2 ]] ; then
		# stable-release series
		LINUX_VER=$(get_version_component_range 1-2)
		LINUX_PATCH=patch-${PV}.xz
		SRC_URI="mirror://kernel/linux/kernel/v${LINUX_V}/${LINUX_PATCH}"
	else
		LINUX_VER=${PV}
		SRC_URI=""
	fi
fi

LINUX_SOURCES="linux-${LINUX_VER}.tar.xz"
SRC_URI+=" mirror://kernel/linux/kernel/v${LINUX_V}/${LINUX_SOURCES}"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~x86"
IUSE="bash-completion"

# pmtools also provides turbostat
# usbip available in seperate package now
RDEPEND="sys-apps/hwids
		!sys-power/pmtools"
DEPEND="${RDEPEND}
		dev-util/patchutils
		virtual/pkgconfig"

S="${WORKDIR}/linux-${LINUX_VER}"

# No make install, can be built with just make's implicit rules.
TARGETS_SIMPLE=(
	usr/gen_init_cpio.c
)

# These have a broken make install, no DESTDIR
TARGET_MAKE_SIMPLE=(
	samples/mei:mei-amt-version
	samples/watchdog:watchdog-simple
	tools/accounting:getdelays
	tools/bpf:bpf_asm
	tools/bpf:bpf_dbg
	# bpf_jit_disasm.c:75:29: error: incompatible type for argument 1 of 'disassembler'
	# bpf_jit_disasm.c:75:16: error: too few arguments to function 'disassembler'
	# bpf_jit_disasm.c:298:50: error: 'DEFFILEMODE' undeclared (first use in this function)
	#tools/bpf:bpf_jit_disasm
	# bfd.h:35:2: error: #error config.h must be included before this header
	#tools/bpf/bpftool:bpftool
	tools/cgroup:cgroup_event_listener
	tools/firewire:nosy-dump
	tools/gpio:gpio-event-mon
	tools/gpio:gpio-hammer
	tools/gpio:lsgpio
	tools/hv:hv_fcopy_daemon
	tools/hv:hv_kvp_daemon
	tools/hv:hv_vss_daemon
	tools/iio:iio_generic_buffer
	tools/iio:iio_event_monitor
	tools/iio:lsiio
	tools/kvm/kvm_stat:kvm_stat
	tools/laptop/dslm:dslm
	tools/laptop/freefall:freefall
	tools/leds:led_hw_brightness_mon
	tools/leds:uledmon
	# acpidbg.c:19:19: fatal error: error.h: No such file or directory
	#tools/power/acpi:acpidbg
	tools/power/acpi:acpidump
	tools/power/acpi:ec
	tools/power/x86/turbostat:turbostat
	tools/power/x86/x86_energy_perf_policy:x86_energy_perf_policy
	tools/thermal/tmon:tmon
	tools/vm:page_owner_sort
	tools/vm:page-types
	tools/vm:slabinfo
)

src_unpack() {
	local paths=(
		"arch/*/include" "arch/*/lib" drivers/acpi/acpica drivers/firewire include
		lib samples scripts tools usr
	)

	# We expect the tar implementation to support the -j option (both
	# GNU tar and libarchive's tar support that).
	echo ">>> Unpacking ${LINUX_SOURCES} (${paths[*]}) to ${PWD}"
	tar --wildcards -xpf "${DISTDIR}"/${LINUX_SOURCES} \
		"${paths[@]/#/linux-${LINUX_VER}/}" || die

	if [[ -n ${LINUX_PATCH} ]] ; then
		eshopts_push -o noglob
		ebegin "Filtering partial source patch"
		filterdiff -p1 ${paths[@]/#/-i } -z "${DISTDIR}"/${LINUX_PATCH} \
			> ${P}.patch || die
		eend $? || die "filterdiff failed"
		eshopts_pop
	fi

	local a
	for a in ${A}; do
		[[ ${a} == ${LINUX_SOURCES} ]] && continue
		[[ ${a} == ${LINUX_PATCH} ]] && continue
		unpack ${a}
	done
}

src_prepare() {
	if [[ -n ${LINUX_PATCH} ]]; then
		epatch "${WORKDIR}"/${P}.patch
	fi
	epatch "${FILESDIR}/${P}-headers.patch"

	sed -i \
		-e '/^nosy-dump.*LDFLAGS/d' \
		-e '/^nosy-dump.*CFLAGS/d' \
		-e '/^nosy-dump.*CPPFLAGS/s,CPPFLAGS =,CPPFLAGS +=,g' \
		"${S}"/tools/firewire/Makefile
	sed -i 's/u_int32_t/uint32_t/g' ${S}/tools/gpio/gpio-event-mon.c

	default
}

src_configure() {
	:
}

src_compile() {
	local karch=$(tc-arch-kernel)

	for s in ${TARGETS_SIMPLE[@]} ; do
		dir=$(dirname $s) src=$(basename $s) bin=${src%.c}
		einfo "Building $s => $bin"
		emake -C $dir -f /dev/null $bin
	done

	for t in ${TARGET_MAKE_SIMPLE[@]} ; do
		dir=${t%:*} target_binfile=${t#*:}
		target=${target_binfile%:*} binfile=${target_binfile#*:}
		[ -z "${binfile}" ] && binfile=$target
		einfo "Building $dir => $binfile (via emake $target)"
		emake -C $dir ARCH=${karch} V=1 $target
	done
}

src_install() {
	into /usr
	for s in ${TARGETS_SIMPLE[@]} ; do
		dir=$(dirname $s) src=$(basename $s) bin=${src%.c}
		einfo "Installing $s => $bin"
		dosbin ${dir}/${bin}
	done

	for t in ${TARGET_MAKE_SIMPLE[@]} ; do
		dir=${t%:*} target_binfile=${t#*:}
		target=${target_binfile%:*} binfile=${target_binfile#*:}
		[ -z "${binfile}" ] && binfile=$target
		einfo "Installing $dir => $binfile"
		dosbin ${dir}/${binfile}
	done

	if use bash-completion; then
		dobashcomp tools/bpf/bpftool/bash-completion/bpftool
	fi

	newconfd "${FILESDIR}"/freefall.confd freefall
	newinitd "${FILESDIR}"/freefall.initd freefall
	prune_libtool_files
}

pkg_postinst() {
	echo
	elog "The cpupower utility is maintained separately at sys-power/cpupower"
	elog "The usbip utility is maintained separately at net-misc/usbip"
	elog "The hpfall tool has been renamed by upstream to freefall; update your config if needed"
	if find /etc/runlevels/ -name hpfall | grep -q .; then
		ewarn "You must change hpfall to freefall in your runlevels!"
	fi
}
