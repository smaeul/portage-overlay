# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

PYTHON_COMPAT=( python{2_7,3_4,3_5} )
PYTHON_REQ_USE="sqlite"

inherit distutils-r1

DESCRIPTION="A media library management system for obsessive-compulsive music geeks"
SRC_URI="mirror://pypi/${PN:0:1}/${PN}/${P}.tar.gz"
HOMEPAGE="http://beets.io/ https://pypi.python.org/pypi/beets"

KEYWORDS="~amd64 ~x86"
SLOT="0"
LICENSE="MIT"
PLUGINS="absubmit beatport bpd chroma convert discogs fetchart import lastgenre
	metasync mpdstats thumbnails web"
IUSE="doc test $PLUGINS"

RDEPEND="
	python_targets_python2_7? ( >=dev-python/enum34-1.0.4[${PYTHON_USEDEP}] )
	dev-python/jellyfish[${PYTHON_USEDEP}]
	dev-python/munkres[${PYTHON_USEDEP}]
	>=dev-python/python-musicbrainz-ngs-0.4[${PYTHON_USEDEP}]
	dev-python/pyyaml[${PYTHON_USEDEP}]
	>=dev-python/six-1.9[${PYTHON_USEDEP}]
	dev-python/unidecode[${PYTHON_USEDEP}]
	>=media-libs/mutagen-1.33[${PYTHON_USEDEP}]
	doc? ( dev-python/sphinx[${PYTHON_USEDEP}] )
	test? (
		dev-python/beautifulsoup:4[${PYTHON_USEDEP}]
		dev-python/discogs-client[${PYTHON_USEDEP}]
		dev-python/flask[${PYTHON_USEDEP}]
		dev-python/mock[${PYTHON_USEDEP}]
		dev-python/pathlib[${PYTHON_USEDEP}]
		dev-python/pylast[${PYTHON_USEDEP}]
		dev-python/python-mpd[${PYTHON_USEDEP}]
		dev-python/pyxdg[${PYTHON_USEDEP}]
		dev-python/rarfile[${PYTHON_USEDEP}]
		dev-python/responses[${PYTHON_USEDEP}]
	)
	absubmit? ( dev-python/requests[${PYTHON_USEDEP}] )
	beatport? ( >=dev-python/requests-oauthlib-0.6.1[${PYTHON_USEDEP}] )
	bpd? ( media-libs/gstreamer:1.0[introspection] )
	chroma? ( dev-python/pyacoustid[${PYTHON_USEDEP}] )
	convert? ( virtual/ffmpeg[encode] )
	discogs? ( >=dev-python/discogs-client-2.2.1[${PYTHON_USEDEP}] )
	fetchart? ( dev-python/requests[${PYTHON_USEDEP}] )
	import? ( dev-python/rarfile[${PYTHON_USEDEP}] )
	lastgenre? ( dev-python/pylast[${PYTHON_USEDEP}] )
	metasync? ( dev-python/dbus-python[${PYTHON_USEDEP}] )
	mpdstats? ( >=dev-python/python-mpd-0.4.2[${PYTHON_USEDEP}] )
	thumbnails? (
		dev-python/pyxdg[${PYTHON_USEDEP}]
		python_targets_python2_7? ( dev-python/pathlib[${PYTHON_USEDEP}] )
	)
	web? (
		dev-python/flask[${PYTHON_USEDEP}]
		dev-python/flask-cors[${PYTHON_USEDEP}]
	)
"
DEPEND="${RDEPEND}"

src_prepare() {
	default

	for flag in ${PLUGINS//import}; do
		if ! use ${flag}; then
			if test -d beetsplug/${flag}; then
				rm -r beetsplug/${flag} || die "Unable to remove ${flag} plugin"
			else
				rm beetsplug/${flag}.py || die "Unable to remove ${flag} plugin"
			fi
		fi
	done

	for flag in bpd lastgenre metasync web; do
		if ! use ${flag}; then
			sed -i "/beetsplug.${flag}/d" setup.py || \
				die "Unable to disable ${flag} plugin "
		fi
	done
}

python_compile_all() {
	use doc && emake -C docs html
}

python_test() {
	cd test
	use bpd || rm test/test_player.py || die "Failed"
	use web || rm test_web.py || die "Failed to remove test_web.py"
	"${PYTHON}" testall.py || die "Testsuite failed"
}

python_install_all() {
	distutils-r1_python_install_all

	doman man/beet.1 man/beetsconfig.5
	use doc && dohtml -r docs/_build/html/
}
