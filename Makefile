getprop = $(shell grep "^$(1)=" module.prop | head -n1 | cut -d'=' -f2)

MODNAME ?= $(call getprop,id)
MODVER ?= $(call getprop,version)
ZIP = $(MODNAME)-$(MODVER).zip

ARCHES := arm64 arm x86_64 x86
ARCH ?= arm64

all: $(ZIP)

zip: $(ZIP)

%.zip: clean
	zip -r9 $(ZIP) . -x $(MODNAME)-*.zip LICENSE CLAUDE.md README.md CHANGELOG.md CHECKLIST.md cliff.toml .gitignore .gitattributes .dockerignore Makefile Dockerfile /hooks/* /scripts/* /tests/* /out/* /.git* /.claude*

install: $(ZIP)
	adb push $(ZIP) /sdcard/
	echo '/data/adb/magisk/busybox unzip -p "/sdcard/$(ZIP)" META-INF/com/google/android/update-binary | /data/adb/magisk/busybox sh /proc/self/fd/0 x x "/sdcard/$(ZIP)"' | adb shell su -c sh -
	adb shell rm -f "/sdcard/$(ZIP)"

clean:
	rm -f *.zip
	rm -rf out out-*

setup:
	ln -sf ../../hooks/pre-commit .git/hooks/pre-commit

build-strace:
	DOCKER_BUILDKIT=1 docker build \
	    --build-arg TARGET_ARCH=$(ARCH) \
	    --target=binary --output=type=local,dest=out-$(ARCH)/ .
	mkdir -p strace-bin/$(ARCH)
	cp out-$(ARCH)/strace strace-bin/$(ARCH)/strace
	rm -rf out-$(ARCH)

build-strace-all:
	@for arch in $(ARCHES); do \
	    echo "=== Building strace for $$arch ==="; \
	    $(MAKE) build-strace ARCH=$$arch; \
	done

test-strace:
	./tests/test-strace-binary.sh strace-bin/$(ARCH)/strace $(ARCH)

test-strace-all:
	@for arch in $(ARCHES); do \
	    echo "=== Testing strace for $$arch ==="; \
	    $(MAKE) test-strace ARCH=$$arch; \
	done

update:
	curl -fS -o META-INF/com/google/android/update-binary.tmp https://raw.githubusercontent.com/topjohnwu/Magisk/master/scripts/module_installer.sh && \
	mv META-INF/com/google/android/update-binary.tmp META-INF/com/google/android/update-binary

.PHONY: all zip install clean setup update build-strace build-strace-all test-strace test-strace-all
