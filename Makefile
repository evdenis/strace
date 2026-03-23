getprop = $(shell grep "^$(1)=" module.prop | head -n1 | cut -d'=' -f2)

MODNAME ?= $(call getprop,id)
MODVER ?= $(call getprop,version)
ZIP = $(MODNAME)-$(MODVER).zip

all: $(ZIP)

zip: $(ZIP)

%.zip: clean
	zip -r9 $(ZIP) . -x $(MODNAME)-*.zip LICENSE CLAUDE.md README.md CHANGELOG.md CHECKLIST.md cliff.toml .gitignore .gitattributes .dockerignore Makefile Dockerfile build-strace.sh /hooks/* /tests/* /out/* /.git* /.claude*

install: $(ZIP)
	adb push $(ZIP) /sdcard/
	echo '/data/adb/magisk/busybox unzip -p "/sdcard/$(ZIP)" META-INF/com/google/android/update-binary | /data/adb/magisk/busybox sh /proc/self/fd/0 x x "/sdcard/$(ZIP)"' | adb shell su -c sh -
	adb shell rm -f "/sdcard/$(ZIP)"

clean:
	rm -f *.zip

setup:
	ln -sf ../../hooks/pre-commit .git/hooks/pre-commit

build-strace:
	DOCKER_BUILDKIT=1 docker build \
	    --target=binary --output=type=local,dest=out/ .
	cp out/strace system/bin/strace
	rm -rf out

test-strace:
	./tests/test-strace-binary.sh system/bin/strace arm64

update:
	curl -fS -o META-INF/com/google/android/update-binary.tmp https://raw.githubusercontent.com/topjohnwu/Magisk/master/scripts/module_installer.sh && \
	mv META-INF/com/google/android/update-binary.tmp META-INF/com/google/android/update-binary

.PHONY: all zip install clean setup update build-strace test-strace
