help:
	@echo "Please use \`make <target>' where <target> is one of:"
	@echo "  help            to show this message"
	@echo "  lint            to lint the fixture generation scripts"
	@echo "  clean           to remove fixture data and 'gnupghome'"
	@echo "  fixtures        to create all fixture data"
	@echo "  fixtures/docker to create Docker fixture data"
	@echo "  fixtures/drpm   to create DRPM fixture data with signed packages"
	@echo "  fixtures/drpm-unsigned"
	@echo "                  to create DRPM fixtures with unsigned packages"
	@echo "  fixtures/python to create Python fixture data"
	@echo "  fixtures/rpm    to create RPM fixture data with signed packages"
	@echo "  fixtures/rpm-erratum"
	@echo "                  to create a JSON erratum referencing the RPM fixtures"
	@echo "  fixtures/rpm-invalid-updateinfo"
	@echo "                  to create RPM fixtures with updated updateinfo.xml"
	@echo "  fixtures/rpm-mirrorlist-bad"
	@echo "  fixtures/rpm-mirrorlist-good"
	@echo "  fixtures/rpm-mirrorlist-mixed"
	@echo "                  to create a mirrorlist text file containing one or"
	@echo "                  more entries. 'bad' and 'good' reference unusable"
	@echo "                  and usable repositories, respectively. 'mixed'"
	@echo "                  references both."
	@echo "  fixtures/rpm-pkglists-updateinfo"
	@echo "                  to create RPM fixtures with multiple pkglists and"
	@echo "                  collections in updateinfo.xml"
	@echo "  fixtures/rpm-unsigned"
	@echo "                  to create RPM fixture data with unsigned packages"
	@echo "  fixtures/rpm-updated-updateinfo"
	@echo "                  to create RPM fixtures with invalid updateinfo.xml"
	@echo "  fixtures/srpm"
	@echo "                  to create SRPM fixture data with signed packages"
	@echo "  fixtures/srpm-unsigned"
	@echo "                  to create SRPM fixture data with unsigned packages"
	@echo "  gnupghome       to create a GnuPG home directory and import the"
	@echo "                  Pulp QE public key"

clean:
	rm -rf fixtures/* gnupghome

# xargs communicates return values better than find's `-exec` argument.
lint:
	find . -name '*.sh' -print0 | xargs -0 shellcheck

all: fixtures
	$(warning The `all` target is deprecated. Use `fixtures` instead.)

fixtures: fixtures/docker \
	fixtures/drpm \
	fixtures/drpm-unsigned \
	fixtures/python \
	fixtures/rpm \
	fixtures/rpm-erratum \
	fixtures/rpm-invalid-updateinfo \
	fixtures/rpm-mirrorlist-bad \
	fixtures/rpm-mirrorlist-good \
	fixtures/rpm-mirrorlist-mixed \
	fixtures/rpm-pkglists-updateinfo \
	fixtures/rpm-unsigned \
	fixtures/rpm-updated-updateinfo \
	fixtures/srpm \
	fixtures/srpm-unsigned

fixtures/docker:
	docker/gen-fixtures.sh $@

fixtures/drpm: gnupghome
	GNUPGHOME=$$(realpath -e gnupghome) rpm/gen-fixtures-delta.sh \
		--signing-key ./rpm/GPG-RPM-PRIVATE-KEY-pulp-qe $@ rpm/assets-drpm

fixtures/drpm-unsigned:
	rpm/gen-fixtures-delta.sh $@ rpm/assets-drpm

fixtures/python:
	python/gen-fixtures.sh $@ python/assets

fixtures/rpm: gnupghome
	GNUPGHOME=$$(realpath -e gnupghome) rpm/gen-fixtures.sh \
		--signing-key ./rpm/GPG-RPM-PRIVATE-KEY-pulp-qe $@ rpm/assets

fixtures/rpm-erratum:
	rpm/gen-erratum.sh $@ rpm/assets

fixtures/rpm-invalid-updateinfo:
	rpm/gen-patched-fixtures.sh $@ rpm/invalid-updateinfo.patch

# NOTE: There is no known specification (syntax, naming, etc) of mirrorlist
# files. These files are modeled on CentOS mirrorlists. See:
# http://mirrorlist.centos.org/?release=6&arch=x86_64&repo=os. For an example of
# an alternate implementation, see: https://www.archlinux.org/mirrorlist/.
fixtures/rpm-mirrorlist-bad:
	echo http://localhost:8000/fixtures/rpmm-unsigned/ > $@

fixtures/rpm-mirrorlist-good: fixtures/rpm-unsigned
	echo http://localhost:8000/fixtures/rpm-unsigned/ > $@

fixtures/rpm-mirrorlist-mixed: fixtures/rpm-unsigned
	echo -e 'http://localhost:8000/fixtures/rpmm-unsigned/\nhttp://localhost:8000/fixtures/rpm-unsigned/' > $@

fixtures/rpm-pkglists-updateinfo:
	rpm/gen-patched-fixtures.sh $@ rpm/pkglists-updateinfo.patch

fixtures/rpm-unsigned:
	rpm/gen-fixtures.sh $@ rpm/assets

fixtures/rpm-updated-updateinfo:
	rpm/gen-patched-fixtures.sh $@ rpm/updated-updateinfo.patch

fixtures/srpm: gnupghome
	GNUPGHOME=$$(realpath -e gnupghome) rpm/gen-fixtures.sh \
		--signing-key ./rpm/GPG-RPM-PRIVATE-KEY-pulp-qe $@ rpm/assets-srpm

fixtures/srpm-unsigned:
	rpm/gen-fixtures.sh $@ rpm/assets-srpm

gnupghome:
	install -dm700 gnupghome
	GNUPGHOME=$$(realpath -e gnupghome) gpg --import rpm/GPG-RPM-PRIVATE-KEY-pulp-qe

.PHONY: help lint clean all
