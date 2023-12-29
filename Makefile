# Copyright (C) 2017-2023 Fredrik Öhrström
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

$(shell mkdir -p build)

define DQUOTE
"
endef

#" make editor quote matching happy.

HAS_GIT=$(shell git rev-parse --is-inside-work-tree >/dev/null 2>&1 ; echo $$?)

ifneq ($(HAS_GIT), 0)
# We have no git used manually set version number.
VERSION:=1.0.0
COMMIT_HASH:=
DEBVERSION:=1.0.0
else
# We have git, extract information from it.
    SUPRE=
	SUPOST=

	ifneq ($(SUDO_USER),)
        # Git has a security check to prevent the wrong user from running inside the git repository.
        # When we run "sudo make install" this will create problems since git is running as root instead.
        # Use SUPRE/SUPOST to use su to switch back to the user for the git commands.
        SUPRE=su -c $(DQUOTE)
        SUPOST=$(DQUOTE) $(SUDO_USER)
    endif

    COMMIT_HASH?=$(shell $(SUPRE) git log --pretty=format:'%H' -n 1 $(SUPOST))
    TAG?=$(shell $(SUPRE) git describe --tags $(SUPOST))
    BRANCH?=$(shell $(SUPRE) git rev-parse --abbrev-ref HEAD $(SUPOST))
    CHANGES?=$(shell $(SUPRE) git status -s | grep -v '?? ' $(SUPOST))

    ifeq ($(COMMIT),$(TAG_COMMIT))
        # Exactly on the tagged commit. The version is the tag!
        VERSION:=$(TAG)
        DEBVERSION:=$(TAG)
    else
        VERSION:=$(TAG)++
        DEBVERSION:=$(TAG)++
    endif

    ifneq ($(strip $(CHANGES)),)
        # There are changes, signify that with a +changes
        VERSION:=$(VERSION) with uncommitted changes
        COMMIT_HASH:=$(COMMIT_HASH) but with uncommitted changes
        DEBVERSION:=$(DEBVERSION)l
    endif

endif

$(info Building $(VERSION))

$(shell echo "$(VERSION)" > build/VERSION)

all: release

help:
	@echo "Usage: make (release|debug|asan|clean|clean-all)"
	@echo "       if you have both linux64, winapi64 and arm32 configured builds,"
	@echo "       then add linux64, winapi64 or arm32 to build only for that particular host."
	@echo "E.g.:  make debug winapi64"
	@echo "       make asan"
	@echo "       make release linux64"

BUILDDIRS:=$(dir $(realpath $(filter-out build/default/%,$(wildcard build/*/spec.mk))))
FIRSTDIR:=$(word 1,$(BUILDDIRS))

ifeq (,$(BUILDDIRS))
    ifneq (clean,$(findstring clean,$(MAKECMDGOALS)))
       $(error Run configure first!)
    endif
endif

VERBOSE?=@

ifeq (winapi64,$(findstring winapi64,$(MAKECMDGOALS)))
BUILDDIRS:=$(filter %x86_64-w64-mingw32%,$(BUILDDIRS))
endif

ifeq (linux64,$(findstring linux64,$(MAKECMDGOALS)))
BUILDDIRS:=$(filter %x86_64-pc-linux-gnu%,$(BUILDDIRS))
endif

ifeq (osx64,$(findstring osx64,$(MAKECMDGOALS)))
BUILDDIRS:=$(filter %x86_64-apple-darwin%,$(BUILDDIRS))
endif

ifeq (arm32,$(findstring arm32,$(MAKECMDGOALS)))
BUILDDIRS:=$(filter %arm-unknown-linux-gnueabihf%,$(BUILDDIRS))
endif

release:
	@echo Building release for $(words $(BUILDDIRS)) host\(s\).
	@for x in $(BUILDDIRS); do echo; echo Bulding $$(basename $$x) ; $(MAKE) --no-print-directory -C $$x release ; done

debug:
	@echo Building debug for $(words $(BUILDDIRS)) host\(s\).
	@for x in $(BUILDDIRS); do echo; echo Bulding $$(basename $$x) ; $(MAKE) --no-print-directory -C $$x debug ; done

asan:
	@echo Building asan for $(words $(BUILDDIRS)) host\(s\).
	@for x in $(BUILDDIRS); do echo; echo Bulding $$(basename $$x) ; $(MAKE) --no-print-directory -C $$x asan ; done

lcov:
	@echo Generating code coverage $(words $(BUILDDIRS)) host\(s\).
	@for x in $(BUILDDIRS); do echo; echo Bulding $$(basename $$x) ; $(MAKE) --no-print-directory -C $$x debug lcov ; done

dist:
	@$(MAKE) --no-print-directory -C $(FIRSTDIR) release $(shell pwd)/dist/xmq.c $(shell pwd)/dist/xmq.h

.PHONY: dist

test: test_release
testd: test_debug
testa: test_asan

test_release:
	@echo "Running release tests"
	@for x in $(BUILDDIRS); do echo; if [ ! -f $$x/release/testinternals ]; then echo "Run make first. $$x/release/testinternals not found."; exit 1; fi ; $$x/release/testinternals ; done
	@for x in $(BUILDDIRS); do echo;  if [ ! -f $$x/release/testinternals ]; then echo "Run make first. $$x/release/testinternals not found."; exit 1; fi ; ./tests/test.sh $$x/release $$x/release/test_output ; done

test_debug:
	@echo "Running debug tests"
	@for x in $(BUILDDIRS); do echo; if [ ! -f $$x/debug/testinternals ]; then echo "Run make first. $$x/debug/testinternals not found."; exit 1; fi ; $$x/debug/testinternals ; done
	@for x in $(BUILDDIRS); do echo;  if [ ! -f $$x/debug/testinternals ]; then echo "Run make first. $$x/debug/testinternals not found."; exit 1; fi ; ./tests/test.sh $$x/debug $$x/debug/test_output ; done

test_asan:
	@echo "Running asan tests"
	@for x in $(BUILDDIRS); do echo; if [ ! -f $$x/asan/testinternals ]; then echo "Run make first. $$x/asan/testinternals not found."; exit 1; fi ; $$x/asan/testinternals ; done
	@for x in $(BUILDDIRS); do echo;  if [ ! -f $$x/asan/testinternals ]; then echo "Run make first. $$x/asan/testinternals not found."; exit 1; fi ; ./tests/test.sh $$x/asan $$x/asan/test_output ; done

clean:
	@echo "Removing release, debug, asan, gtkdoc build dirs."
	@for x in $(BUILDDIRS); do echo; rm -rf $$x/release $$x/debug $$x/asan $$x/generated_autocomplete.h; done
	@rm -rf build/gtkdoc

clean-all:
	@echo "Removing build directory containing configuration and artifacts."
	$(VERBOSE)rm -rf build

DESTDIR?=/usr/local
install:
	install -Dm 755 -s build/x86_64-pc-linux-gnu/release/xmq $(DESTDIR)/bin/xmq
	install -Dm 755 scripts/xmq-less $(DESTDIR)/bin/xmq-less
	install -Dm 644 doc/xmq.1 $(DESTDIR)/man/man1/xmq.1
	install -Dm 644 scripts/autocompletion_for_xmq.sh /etc/bash_completion.d/xmq

uninstall:
	rm -f $(DESTDIR)/bin/xmq
	rm -f $(DESTDIR)/bin/xmq-less
	rm -f $(DESTDIR)/man/man1/xmq.1
	rm -f /etc/bash_completion.d/xmq

linux64:

arm32:

winapi64:

PACKAGE:=libxmq
PACKAGE_BUGREPORT:=
PACKAGE_NAME:=libxmq_name
PACKAGE_STRING:=libxmq_string
PACKAGE_TARNAME:=libxmq_tar
PACKAGE_URL:=https://libxmq.org/releases/libxmq.tgz
PACKAGE_VERSION:=0.9

build/gtkdocentities.ent:
	@echo '<!ENTITY package "$(PACKAGE)">' > $@
	@echo '<!ENTITY package_bugreport "$(PACKAGE_BUGREPORT)">' >> $@
	@echo '<!ENTITY package_name "$(PACKAGE_NAME)">' >> $@
	@echo '<!ENTITY package_string "$(PACKAGE_STRING)">' >> $@
	@echo '<!ENTITY package_tarname "$(PACKAGE_TARNAME)">' >> $@
	@echo '<!ENTITY package_url "$(PACKAGE_URL)">' >> $@
	@echo '<!ENTITY package_version "$(PACKAGE_VERSION)">' >> $@
	echo Created $@

gtkdoc: build/gtkdoc

build/gtkdoc: build/gtkdocentities.ent
	rm -rf build/gtkdoc
	mkdir -p build/gtkdoc
	mkdir -p build/gtkdoc/html
	cp scripts/libxmq-docs.xml build/gtkdoc
	(cd build/gtkdoc; gtkdoc-scan --module=libxmq --source-dir ../../src/main/c/)
	(cd build/gtkdoc; gtkdoc-mkdb --module libxmq --sgml-mode --source-dir ../../src/main/c --source-suffixes h  --ignore-files "xmq.c testinternals.c xmq-cli.c")
	cp build/gtkdocentities.ent build/gtkdoc/xml
	(cd build/gtkdoc/html; gtkdoc-mkhtml libxmq ../libxmq-docs.xml)
	(cd build/gtkdoc; gtkdoc-fixxref --module=libxmq --module-dir=html --html-dir=html)

.PHONY: all release debug asan test test_release test_debug clean clean-all help linux64 winapi64 arm32 gtkdoc build/gtkdoc

pom.xml: pom.xmq
	xmq pom.xmq to-xml > pom.xml

mvn:
	mvn package

TODAY:=$(shell date +'%Y-%m-%d %H:%M')

.PHONY: web
web: build/web/index.html

WEBXMQ:=build/default/release/xmq

.PHONY: build/web/index.html
build/web/index.html:
	@mkdir -p build/web/resources
	@$(WEBXMQ) web/50x.htmq to-html > build/web/50x.html
	@$(WEBXMQ) web/404.htmq to-html > build/web/404.html
	@cp doc/xmq.pdf  build/web
	@cp web/resources/style.css  build/web/resources
	@cp web/resources/code.js  build/web/resources
	@cp web/resources/shiporder.xml  build/web/resources/shiporder.xml
	@cp web/resources/car.xml  build/web/resources/car.xml
	@cp web/resources/config.xmq  build/web/resources/
	@cp web/resources/welcome_traveller.htmq  build/web/resources/welcome_traveller.htmq
	@cp web/resources/welcome_traveller.html  build/web/resources/welcome_traveller.html
	@cp web/resources/sugar.xmq  build/web/resources/sugar.xmq
# Extract the css
	$(WEBXMQ) web/resources/shiporder.xml render-html --onlystyle > build/web/resources/xmq.css
# Generate the xmq from the xml
	$(WEBXMQ) web/resources/shiporder.xml to-xmq > build/web/resources/shiporder.xmq
# Render the xmq in html
	$(WEBXMQ) web/resources/shiporder.xml render-html --id=ex1 --class=w40 --lightbg --nostyle  > build/rendered_shiporder_xmq.xml
# Generate compact shiporder
	$(WEBXMQ) web/resources/shiporder.xml to-xmq --compact > build/shiporder_compact.xmq
# Render compact xmq in html
	$(WEBXMQ) web/resources/shiporder.xml render-html --compact --id=ex1c --class=w40 --lightbg --nostyle  > build/rendered_shiporder_xmq_compact.xml
# Render config
	$(WEBXMQ) web/resources/config.xmq render-html --class=w40 --lightbg --nostyle  > build/rendered_config_xmq.xml
	$(WEBXMQ) --root=myconf web/resources/config.xmq to-xml  > build/config.xml
# Render multi
	$(WEBXMQ) web/resources/multi.xmq render-html --class=w40 --lightbg --nostyle  > build/rendered_multi_xmq.xml
	$(WEBXMQ) web/resources/multi.xmq render-html --class=w40 --lightbg --nostyle --compact  > build/rendered_multi_compact_xmq.xml
	$(WEBXMQ) web/resources/multi.xmq to-xml > build/multi.xml
# Render car xmq in html
	$(WEBXMQ) web/resources/car.xml render-html --class=w40 --lightbg --nostyle  > build/rendered_car_xmq.xml
	$(WEBXMQ) web/resources/car.xml to-xml  > build/web/resources/car.xml
	$(WEBXMQ) web/resources/car.xml to-xmq > build/web/resources/car.xmq
# Tokenize the sugar.xmq
	echo -n "<span>" > build/sugar_xmq.xml
	$(WEBXMQ) web/resources/sugar.xmq tokenize --type=html >> build/sugar_xmq.xml
	echo -n "</span>" >> build/sugar_xmq.xml
# Raw xml from corners and syntactic sugar.
	$(WEBXMQ) web/resources/syntactic_sugar.xmq tokenize --type=html > build/syntactic_sugar_xmq.xml
	$(WEBXMQ) web/resources/corners.xmq tokenize --type=html > build/corners_xmq.xml
	$(WEBXMQ) web/resources/compound.xmq tokenize --type=html > build/compound_xmq.xml
# Render json
	$(WEBXMQ) web/resources/instances.json render-html --class=w80 --lightbg --nostyle > build/instances_json.xml
	cp web/resources/instances.json build/instances.json
# Render the welcome traveller xmq in html
	$(WEBXMQ) web/resources/welcome_traveller.htmq render-html --id=ex2 --class=w40 --lightbg --nostyle  > build/rendered_welcome_traveller_xmq.xml
	$(WEBXMQ) web/resources/welcome_traveller.html render-html --id=ex2 --class=w40 --lightbg --nostyle  > build/rendered_welcome_traveller_back_xmq.xml
	$(WEBXMQ) --trim=none web/resources/welcome_traveller.html to-htmq --escape-non-7bit | $(WEBXMQ) - render-html --id=ex2 --class=w40 --lightbg --nostyle  > build/rendered_welcome_traveller_back_notrim_xmq.xml
# Render the same but compact
	$(WEBXMQ) web/resources/welcome_traveller.htmq render-html --id=ex2 --class=w40 --lightbg --nostyle --compact > build/rendered_welcome_traveller_xmq_compact.xml
	$(WEBXMQ) web/resources/welcome_traveller.htmq to-htmq > build/web/resources/welcome_traveller.htmq
	$(WEBXMQ) web/resources/welcome_traveller.htmq to-html > build/welcome_traveller_nopp.html
	$(WEBXMQ) pom.xml render-html --id=expom --class=w80 --lightbg --nostyle > build/pom_rendered.xml
	$(WEBXMQ) data.xslt render-html --id=exxslt --class=w80 --lightbg --nostyle > build/xslt_rendered.xml
	$(WEBXMQ) web/index.htmq \
		replace-entity DATE "$(TODAY)" \
		replace-entity SHIPORDER_XML --with-text-file=web/resources/shiporder.xml \
		replace-entity SHIPORDER_XMQ --with-file=build/rendered_shiporder_xmq.xml \
		replace-entity SHIPORDER_XMQ_COMPACT --with-file=build/rendered_shiporder_xmq_compact.xml \
		replace-entity CONFIG_XMQ --with-file=build/rendered_config_xmq.xml \
		replace-entity CONFIG_XML --with-text-file=build/config.xml \
		replace-entity MULTI_XMQ --with-file=build/rendered_multi_xmq.xml \
		replace-entity MULTI_COMPACT_XMQ --with-file=build/rendered_multi_compact_xmq.xml \
		replace-entity MULTI_XML --with-text-file=build/multi.xml \
		replace-entity CAR_XML --with-text-file=web/resources/car.xml \
		replace-entity CAR_XMQ --with-file=build/rendered_car_xmq.xml \
		replace-entity CORNERS_XMQ --with-file=build/corners_xmq.xml \
		replace-entity COMPOUND_XMQ --with-file=build/compound_xmq.xml \
		replace-entity INSTANCES_XMQ --with-file=build/instances_json.xml \
		replace-entity INSTANCES_JSON --with-text-file=build/instances.json \
		replace-entity SYNTACTIC_SUGAR_XMQ --with-file=build/syntactic_sugar_xmq.xml \
		replace-entity WELCOME_TRAVELLER_HTMQ --with-file=build/rendered_welcome_traveller_xmq.xml \
		replace-entity WELCOME_TRAVELLER_BACK_HTMQ --with-file=build/rendered_welcome_traveller_back_xmq.xml \
		replace-entity WELCOME_TRAVELLER_BACK_NOTRIM_HTMQ --with-file=build/rendered_welcome_traveller_back_notrim_xmq.xml \
		replace-entity WELCOME_TRAVELLER_HTML --with-text-file=build/web/resources/welcome_traveller.html \
		replace-entity WELCOME_TRAVELLER_HTMQ_COMPACT --with-file=build/rendered_welcome_traveller_xmq_compact.xml \
		replace-entity WELCOME_TRAVELLER_NOPP_HTML --with-text-file=build/welcome_traveller_nopp.html \
		replace-entity POM_RENDERED --with-file=build/pom_rendered.xml \
		replace-entity XSLT_RENDERED --with-file=build/xslt_rendered.xml \
		to-html > build/web/index.html
	@$(WEBXMQ) web/index.htmq render-html > build/web/resources/index_htmq.html
	@echo Updated $@


#	@$(WEBXMQ) --trim=none build/_EX1_.html to-xmq --compact  > build/_EX1_.htmq
#	@cat web/index.htmq | sed -e "s/_EX1_/$$(sed 's:/:\\/:g' build/_EX1_.htmq | sed 's/\&/\\\&/g')/g" > build/tmp.htmq
#	@$(WEBXMQ) build/tmp2.htmq to-html > build/web/index.html
#	@(cd doc; make)
#	@cp doc/xmq.pdf build/web
#	@cp web/favicon.ico build/web
#	@cp web/resources/* build/web/resources
#	@echo "Generated build/web/index.html"
