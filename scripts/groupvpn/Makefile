# GroupVPN make script
# Tested with: ....

ACIS_REL_NOTES	:=	$(shell readlink -m ../../docs/release_notes.txt)
ACIS_REL_VER	:=	$(shell grep -oP '(?<=^Revision\s)[\d\.]+$$' ${ACIS_REL_NOTES} | sort -V | tail -n 1)
ACIS_BIN_ZIP	:=	$(shell readlink -m ../build/acisp2p.${ACIS_REL_VER}.zip)
ACIS_SRC_ZIP	:=	$(shell readlink -m ../build/acisp2p.src.${ACIS_REL_VER}.zip)
ACIS_BIN_NET	:=	http://www.grid-appliance.org/files/ipop/ipop.zip
ACIS_BUILD_EXEC	:=	$(shell readlink -m ../build/binary_release.sh)
ACIS_BUILD_DIR	:=	$(shell dirname ${ACIS_BUILD_EXEC})
NSIS_MAKE_EXEC	:= 'C:/Program Files/NSIS/makensis.exe'

all: nsis arch-pkg

nsis: ipop.zip
	rm -rf acisp2p
	unzip ipop.zip
	grep -P -50 '^License$$' acisp2p/README > acisp2p/LICENSE
	wine ${NSIS_MAKE_EXEC} GroupVPN.nsi

ipop.zip:
	[ -f ${ACIS_BIN_ZIP} ] || ( pushd ${ACIS_BUILD_DIR}; ${ACIS_BUILD_EXEC} ${ACIS_REL_VER}; popd )
	cp ${ACIS_BIN_ZIP} $(CURDIR)/ipop.zip || wget -qr -O $(CURDIR)/ipop.zip ${ACIS_BIN_NET}

.ONESHELL:
arch-pkgsrc: ipop.zip
	cd arch
	ln -s $(CURDIR)/ipop.zip
	makepkg --source -f --skipinteg

.ONESHELL:
arch-pkg: ipop.zip
	cd arch
	ln -s $(CURDIR)/ipop.zip
	makepkg -f --skipinteg

clean: clean-local clean-arch clean-upstream

clean-local:
	rm -rf acisp2p acisp2p.*.zip ipop.zip groupvpn.*.exe

clean-arch:
	rm -rf arch/groupvpn-*-*.tar.* arch/{ipop.zip,src,pkg}

clean-upstream:
	rm -rf ${ACIS_BIN_ZIP} ${ACIS_SRC_ZIP}
