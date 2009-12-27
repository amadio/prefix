# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-libs/libnet/libnet-1.1.4-r1.ebuild,v 1.3 2009/12/24 17:51:31 pacho Exp $

EAPI="2"

inherit eutils

DESCRIPTION="library to provide an API for commonly used low-level network functions (mainly packet injection)"
HOMEPAGE="http://libnet-dev.sourceforge.net/"
SRC_URI="mirror://sourceforge/project/libnet-dev/libnet-dev/${P}/${P}.tar.gz"

LICENSE="LGPL-2"
SLOT="1.1"
KEYWORDS="~x86-freebsd ~amd64-linux ~x86-linux ~ppc-macos ~x86-macos"
IUSE="doc"

DEPEND="sys-devel/autoconf"
RDEPEND=""

src_prepare() {
	epatch "${FILESDIR}"/${P}-zero-pointers-after-free.patch
}

src_install(){
	emake DESTDIR="${D}" install || die "Failed to install"

	dodoc README \
		doc/{BUGS,CHANGELOG,CONTRIB,DESIGN_NOTES,MIGRATION} \
		doc/{PACKET_BUILDING,PORTED,RAWSOCKET_NON_SEQUITUR,TODO}
	if use doc ; then
		dohtml -r doc/html/*
		docinto sample
		dodoc sample/*.[ch]
	fi
}
