# Copyright 1999-2007 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/gnome-base/gnome-common/gnome-common-2.12.0.ebuild,v 1.16 2007/08/06 05:29:16 kumba Exp $

EAPI="prefix"

inherit gnome2

DESCRIPTION="Common files for development of Gnome packages"
HOMEPAGE="http://www.gnome.org/"

LICENSE="GPL-2"
SLOT="3"
KEYWORDS="~amd64 ~ia64 ~sparc-solaris ~x86"
IUSE=""

DEPEND=""
RDEPEND=""

DOCS="ChangeLog README* doc/usage.txt"

src_unpack() {
	unpack ${A}
	cd "${S}"
	mv doc-build/README README.doc-build
}
