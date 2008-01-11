# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-libs/gtk+/gtk+-2.12.5.ebuild,v 1.1 2008/01/10 21:39:39 eva Exp $

EAPI="prefix"

inherit gnome.org flag-o-matic eutils autotools virtualx multilib

DESCRIPTION="Gimp ToolKit +"
HOMEPAGE="http://www.gtk.org/"

LICENSE="LGPL-2"
SLOT="2"
KEYWORDS="~amd64-linux ~ia64-linux ~x86-linux ~ppc-macos ~x86-macos ~x86-solaris"
IUSE="aqua cups debug doc jpeg tiff vim-syntax xinerama"

RDEPEND="X? (
		x11-libs/libXrender
		x11-libs/libX11
		x11-libs/libXi
		x11-libs/libXt
		x11-libs/libXext
		x11-libs/libXcursor
		x11-libs/libXrandr
		x11-libs/libXfixes
		x11-libs/libXcomposite
		x11-libs/libXdamage
	)
	xinerama? ( x11-libs/libXinerama )
	>=dev-libs/glib-2.13.5
	>=x11-libs/pango-1.17.3
	>=dev-libs/atk-1.10.1
	>=x11-libs/cairo-1.2.0
	!aqua? ( media-libs/fontconfig )
	x11-misc/shared-mime-info
	>=media-libs/libpng-1.2.1
	cups? ( net-print/cups )
	jpeg? ( >=media-libs/jpeg-6b-r2 )
	tiff? ( >=media-libs/tiff-3.5.7 )"

DEPEND="${RDEPEND}
	sys-devel/autoconf
	>=dev-util/pkgconfig-0.9
	=sys-devel/automake-1.7*
	X? (
		x11-proto/xextproto
		x11-proto/xproto
		x11-proto/inputproto
		x11-proto/damageproto
	)
	xinerama? ( x11-proto/xineramaproto )
	doc? (
			>=dev-util/gtk-doc-1.6
			~app-text/docbook-xml-dtd-4.1.2
		 )"
PDEPEND="vim-syntax? ( app-vim/gtk-syntax )"

pkg_setup() {
	if use X && use aqua; then
		eerror "Please enable either X or aqua USE flag, not both"
		die "can't build with X and aqua"
	fi
	if use !aqua && ! built_with_use x11-libs/cairo X; then
		eerror "Please re-emerge x11-libs/cairo with the X USE flag set"
		die "cairo needs the X flag set"
	fi
	if use aqua && ! built_with_use x11-libs/cairo aqua; then
		eerror "Please re-emerge x11-libs/cairo with the aqua USE flag set"
		die "cairo needs the aqua flag set"
	fi
}

set_gtk2_confdir() {
	# An arch specific config directory is used on multilib systems
	has_multilib_profile && GTK2_CONFDIR="/etc/gtk-2.0/${CHOST}"
	GTK2_CONFDIR=${GTK2_CONFDIR:=/etc/gtk-2.0}
}

src_unpack() {
	unpack ${A}
	cd "${S}"

	# use an arch-specific config directory so that 32bit and 64bit versions
	# dont clash on multilib systems
	has_multilib_profile && epatch "${FILESDIR}/${PN}-2.8.0-multilib.patch"

	# Firefox print review crash fix, bug #195644
	epatch "${FILESDIR}/${PN}-2.12.1-firefox-print-preview.patch"

	# Fix printing on ppc64.  Bug #197639
	#epatch "${FILESDIR}/${PN}-2.12.1-cupsutils.patch"

	# -O3 and company cause random crashes in applications. Bug #133469
	replace-flags -O3 -O2
	strip-flags

	# Kill -m* on ppc-macos, as it triggers altivec problems
	[[ ${CHOST} == powerpc-apple-darwin* ]] && filter-flags "-m*"

	use ppc64 && append-flags -mminimal-toc

	# remember, eautoreconf applies elibtoolize.
	# if you remove this, you should manually run elibtoolize
	export WANT_AUTOMAKE=1.7
	cp aclocal.m4 old_macros.m4
	AT_M4DIR="." eautoreconf

	epunt_cxx
}

src_compile() {
	# png always on to display icons (foser)
	local myconf="$(use_enable doc gtk-doc) \
		$(use_with jpeg libjpeg) \
		$(use_with tiff libtiff) \
		$(use_enable xinerama) \
		--with-libpng"
	if use aqua; then
		myconf="${myconf} --with-gdktarget=quartz"
	fi
	if use X; then
		myconf="${myconf} --with-gdktarget=x11 --with-xinput"
	fi

	# Passing --disable-debug is not recommended for production use
	use debug && myconf="${myconf} --enable-debug=yes"

	# need libdir here to avoid a double slash in a path that libtool doesn't
	# grok so well during install (// between $EPREFIX and usr ...)
	econf --libdir="${EPREFIX}/usr/$(get_libdir)" ${myconf} || die "configure failed"

	# add correct framework linking options
	use aqua && for i in gtk demos demos/gtk-demo tests perf; do
		sed -i -e "s:LDFLAGS =:LDFLAGS = -framework AppKit -framework Carbon:" $i/Makefile || die "sed failed"
	done

	emake || die "compile failed"
}

src_test() {
	Xemake check || die
}

src_install() {
	emake DESTDIR="${D}" install || die "Installation failed"

	set_gtk2_confdir
	dodir ${GTK2_CONFDIR}
	keepdir ${GTK2_CONFDIR}

	# see bug #133241
	echo 'gtk-fallback-icon-theme = "gnome"' > "${ED}/${GTK2_CONFDIR}/gtkrc"

	# Enable xft in environment as suggested by <utx@gentoo.org>
	dodir /etc/env.d
	echo "GDK_USE_XFT=1" > "${ED}/etc/env.d/50gtk2"

	dodoc AUTHORS ChangeLog* HACKING NEWS* README*

	# This has to be removed, because it's multilib specific; generated in
	# postinst
	rm "${ED}/etc/gtk-2.0/gtk.immodules"
}

pkg_postinst() {
	# add -framework Carbon to the .pc files
	use aqua && for i in gtk+-2.0.pc  gtk+-quartz-2.0.pc  gtk+-unix-print-2.0.pc; do
		sed -i -e "s:Libs\: :Libs\: -framework Carbon :" ${EPREFIX}/usr/lib/pkgconfig/$i || die "sed failed"
	done

	set_gtk2_confdir

	if [ -d "${EROOT}${GTK2_CONFDIR}" ]; then
		gtk-query-immodules-2.0  > "${EROOT}${GTK2_CONFDIR}/gtk.immodules"
		gdk-pixbuf-query-loaders > "${EROOT}${GTK2_CONFDIR}/gdk-pixbuf.loaders"
	else
		ewarn "The destination path ${EROOT}${GTK2_CONFDIR} doesn't exist;"
		ewarn "to complete the installation of GTK+, please create the"
		ewarn "directory and then manually run:"
		ewarn "  cd ${EROOT}${GTK2_CONFDIR}"
		ewarn "  gtk-query-immodules-2.0  > gtk.immodules"
		ewarn "  gdk-pixbuf-query-loaders > gdk-pixbuf.loaders"
	fi

	if [ -e "${EPREFIX}/usr/lib/gtk-2.0/2.[^1]*" ]; then
		elog "You need to rebuild ebuilds that installed into" "${EPREFIX}/usr/lib/gtk-2.0/2.[^1]*"
		elog "to do that you can use qfile from portage-utils:"
		elog "emerge -va1 \$(qfile -qC ${EPREFIX}/usr/lib/gtk-2.0/2.[^1]*)"
	fi

	elog "Please install app-text/evince for print preview functionality"
}
