# Copyright 1999-2007 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-java/commons-collections/commons-collections-3.2-r1.ebuild,v 1.5 2007/11/25 09:57:55 nelchael Exp $

EAPI="prefix"

JAVA_PKG_IUSE="doc source test"

inherit java-pkg-2 java-ant-2 eutils

DESCRIPTION="Jakarta-Commons Collections Component"
HOMEPAGE="http://jakarta.apache.org/commons/collections/"
SRC_URI="mirror://apache/jakarta/${PN/-//}/source/${P}-src.tar.gz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64 ~ia64 ~x86 ~x86-fbsd ~x86-macos"
IUSE="test-framework"

COMMON_DEP="test-framework? ( =dev-java/junit-3.8* )"
DEPEND=">=virtual/jdk-1.4
	test? ( dev-java/ant-junit )
	${COMMON_DEP}"
RDEPEND=">=virtual/jre-1.4
	${COMMON_DEP}"

S="${WORKDIR}/${P}-src"

src_unpack() {
	unpack ${A}
	rm -v "${S}"/*.jar || die
}

src_compile() {
	local antflags
	if use test-framework; then
		antflags="tf.jar -Djunit.jar=$(java-pkg_getjars junit)"
		#no support for installing two sets of javadocs via dojavadoc atm
		#use doc && antflags="${antflags} tf.javadoc"
	fi
	eant jar $(use_doc) ${antflags}
}

src_test() {
	ANT_TASKS="ant-junit" eant testjar -Djunit.jar="$(java-pkg_getjars junit)"
}

src_install() {
	java-pkg_newjar build/${P}.jar ${PN}.jar
	use test-framework && \
		java-pkg_newjar build/${PN}-testframework-3.2.jar \
			${PN}-testframework.jar

	dodoc README.txt || die
	java-pkg_dohtml *.html || die
	if use doc; then
		java-pkg_dojavadoc build/docs/apidocs
		#use test-framework && java-pkg_dojavadoc build/docs/testframework
	fi
	use source && java-pkg_dosrc src/java/*
}
