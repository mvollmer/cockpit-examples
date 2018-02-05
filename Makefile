COCKPIT_GIT=https://github.com/cockpit-project/cockpit.git
COCKPIT_TEST_IMAGE=$(or $(TEST_OS),fedora-27)
VM_IMAGE=$(CURDIR)/test/images/$(COCKPIT_TEST_IMAGE)

# generate version number from the latest git tag; if the topmost commit is
# tagged (at release time), just use that; if there are commits after that,
# append a ".x" suffix to indicate that's a development snapshot
# if there is no tag (yet), use 0 as version
RELEASEVER=$(shell (git describe --exclude '*jenkins*' || echo 0) | sed 's/-[0-9]\+-g.*/.x/')

default:
	# nothing to do

install:
	install -d $(DESTDIR)/usr/share/cockpit
	cp -r pinger $(DESTDIR)/usr/share/cockpit

dist:
	git ls-files --full-name | tar -cJf cockpit-examples-$(RELEASEVER).tar.xz --files-from=- --transform="flags=r;s|^|cockpit-examples-$(RELEASEVER)/|"

srpm: dist
	rpmbuild -bs \
	  --define "_sourcedir `pwd`" \
	  --define "_srcrpmdir `pwd`" \
	  --define "releasever $(RELEASEVER)" \
	  cockpit-examples.spec

rpm: dist
	mkdir -p output rpmbuild
	rpmbuild -bb \
	  --define "_sourcedir `pwd`" \
	  --define "_specdir `pwd`" \
	  --define "_builddir `pwd`/rpmbuild" \
	  --define "_srcrpmdir `pwd`" \
	  --define "_rpmdir `pwd`/output" \
	  --define "_buildrootdir `pwd`/build" \
	  --define "releasever $(RELEASEVER)" \
	  cockpit-examples.spec
	find output -name '*.rpm' -printf '%f\n' -exec mv {} . \;
	rm -rf rpmbuild build output

bots:
	git fetch --depth=1 $(COCKPIT_GIT)
	git checkout --force FETCH_HEAD -- bots/
	# work around for https://github.com/cockpit-project/cockpit/pull/8595
	for f in cloud-init.iso identity testvm.py; do if [ -L bots/machine/$$f ]; then \
		rm bots/machine/$$f; git show FETCH_HEAD:test/common/$$f > bots/machine/$$f; \
	fi; done
	git reset bots

$(VM_IMAGE): rpm bots
	./bots/image-customize -v -i cockpit -i `pwd`/cockpit-examples-0-1.*.noarch.rpm $(COCKPIT_TEST_IMAGE)

check: $(VM_IMAGE)
	@PYTHONPATH=bots/machine TEST_IMAGE=$(VM_IMAGE) test/check-pinger -v

.PHONY: default install dist rpm srpm check
