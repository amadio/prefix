# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-editors/vim/vim-7.1.213.ebuild,v 1.1 2008/01/09 21:26:52 hawking Exp $

EAPI="prefix"

inherit vim autotools

VIM_VERSION="7.1"
VIM_GENTOO_PATCHES="vim-${VIM_VERSION}-gentoo-patches.tar.bz2"
VIM_ORG_PATCHES="vim-patches-${PV}.tar.gz"
PREFIX_VER="2"

SRC_URI="ftp://ftp.vim.org/pub/vim/unstable/unix/vim-${VIM_VERSION}.tar.bz2
	ftp://ftp.vim.org/pub/vim/extra/vim-${VIM_VERSION}-lang.tar.gz
	ftp://ftp.vim.org/pub/vim/extra/vim-${VIM_VERSION}-extra.tar.gz
	mirror://gentoo/${VIM_GENTOO_PATCHES}
	mirror://gentoo/${VIM_ORG_PATCHES}
	http://dev.gentoo.org/~grobian/distfiles/vim-misc-prefix-${PREFIX_VER}.tar.bz2"

S="${WORKDIR}/vim${VIM_VERSION/.}"
DESCRIPTION="Vim, an improved vi-style text editor"
KEYWORDS="~ppc-aix ~x86-fbsd ~ia64-hpux ~amd64-linux ~ia64-linux ~x86-linux ~ppc-macos ~x86-macos ~sparc-solaris ~sparc64-solaris ~x86-solaris"
IUSE=""
DEPEND="${DEPEND}
	!minimal? ( ~app-editors/vim-core-${PV} )"
RDEPEND="${RDEPEND}
	!<app-editors/nvi-1.81.5-r4
	!minimal? ( ~app-editors/vim-core-${PV} )"
