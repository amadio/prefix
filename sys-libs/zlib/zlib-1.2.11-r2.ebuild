# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI="5"
AUTOTOOLS_AUTO_DEPEND="no"

inherit autotools toolchain-funcs multilib multilib-minimal usr-ldscript

CYGWINPATCHES=(
	"https://github.com/cygwinports/zlib/raw/22a3462cae33a82ad966ea0a7d6cbe8fc1368fec/1.2.11-gzopen_w.patch"
	"https://github.com/cygwinports/zlib/raw/22a3462cae33a82ad966ea0a7d6cbe8fc1368fec/1.2.7-minizip-cygwin.patch"
)

DESCRIPTION="Standard (de)compression library"
HOMEPAGE="https://zlib.net/"
SRC_URI="https://zlib.net/${P}.tar.gz
	http://www.gzip.org/zlib/${P}.tar.gz
	http://www.zlib.net/current/beta/${P}.tar.gz
	elibc_Cygwin? ( ${CYGWINPATCHES[*]} )"

LICENSE="ZLIB"
SLOT="0/1" # subslot = SONAME
KEYWORDS="~ppc-aix ~x64-cygwin ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~m68k-mint ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris ~x86-winnt"
IUSE="minizip static-libs"

DEPEND="minizip? ( ${AUTOTOOLS_DEPEND} )"
RDEPEND="!<dev-libs/libxml2-2.7.7" #309623

src_prepare() {
	epatch "${FILESDIR}"/${PN}-1.2.11-fix-deflateParams-usage.patch
	epatch "${FILESDIR}"/${PN}-1.2.11-minizip-drop-crypt-header.patch #658536

	local p
	use elibc_Cygwin &&
	for p in "${CYGWINPATCHES[@]}"; do
		epatch "${DISTDIR}/${p##*/}"
	done

	if use minizip ; then
		cd contrib/minizip || die
		eautoreconf
	fi

	case ${CHOST} in
	*-cygwin*)
		# do not use _wopen, is a mingw symbol only
		sed -i -e '/define WIDECHAR/d' "${S}"/gzguts.h
		# zlib1.dll is the mingw name, need cygz.dll
		# cygz.dll is loaded by toolchain, put into subdir
		sed -i -e 's|zlib1.dll|win32/cygz.dll|' win32/Makefile.gcc || die
		;;
	esac

	case ${CHOST} in
	*-mingw*|mingw*|*-cygwin*)
		# uses preconfigured Makefile rather than configure script
		multilib_copy_sources
		;;
	esac
}

echoit() { echo "$@"; "$@"; }

multilib_src_configure() {
	case ${CHOST} in
	*-mingw*|mingw*|*-cygwin*)
		;;
	*)      # not an autoconf script, so can't use econf
		local uname=$("${EPREFIX}"/usr/share/gnuconfig/config.sub "${CHOST}" | cut -d- -f3) #347167
		echoit "${S}"/configure \
			$(tc-is-static-only && echo "--static" || echo "--shared") \
			--prefix="${EPREFIX}/usr" \
			--libdir="${EPREFIX}/usr/$(get_libdir)" \
			${uname:+--uname=${uname}} \
			|| die
		;;
	esac

	if use minizip ; then
		local minizipdir="contrib/minizip"
		mkdir -p "${BUILD_DIR}/${minizipdir}" || die
		cd ${minizipdir} || die
		ECONF_SOURCE="${S}/${minizipdir}" \
		econf $(use_enable static-libs static)
	fi
}

multilib_src_compile() {
	case ${CHOST} in
	*-mingw*|mingw*|*-cygwin*)
		emake -f win32/Makefile.gcc STRIP=true PREFIX=${CHOST}-
		sed \
			-e 's|@prefix@|'"${EPREFIX}"'/usr|g' \
			-e 's|@exec_prefix@|${prefix}|g' \
			-e 's|@libdir@|${exec_prefix}/'$(get_libdir)'|g' \
			-e 's|@sharedlibdir@|${exec_prefix}/'$(get_libdir)'|g' \
			-e 's|@includedir@|${prefix}/include|g' \
			-e 's|@VERSION@|'${PV}'|g' \
			zlib.pc.in > zlib.pc || die
		;;
	*)
		emake
		;;
	esac
	use minizip && emake -C contrib/minizip
}

sed_macros() {
	# clean up namespace a little #383179
	# we do it here so we only have to tweak 2 files
	sed -i -r 's:\<(O[FN])\>:_Z_\1:g' "$@" || die
}

multilib_src_install() {
	case ${CHOST} in
	*-mingw*|mingw*|*-cygwin*)
		emake -f win32/Makefile.gcc install \
			BINARY_PATH="${ED}/usr/bin" \
			LIBRARY_PATH="${ED}/usr/$(get_libdir)" \
			INCLUDE_PATH="${ED}/usr/include" \
			SHARED_MODE=1
		# overwrites zlib.pc created from win32/Makefile.gcc #620136
		insinto /usr/$(get_libdir)/pkgconfig
		doins zlib.pc
		;;

	*)
		emake install DESTDIR="${D}" LDCONFIG=:
		gen_usr_ldscript -a z
		;;
	esac
	sed_macros "${ED}"/usr/include/*.h

	if use minizip ; then
		emake -C contrib/minizip install DESTDIR="${D}"
		sed_macros "${ED}"/usr/include/minizip/*.h
	fi

	use static-libs || rm -f "${ED}"/usr/$(get_libdir)/lib{z,minizip}.{a,la} #419645
}

multilib_src_install_all() {
	dodoc FAQ README ChangeLog doc/*.txt
	use minizip && dodoc contrib/minizip/*.txt
}
