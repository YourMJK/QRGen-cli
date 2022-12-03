.PHONY: build distclean

build:
	swift build --configuration release && \
	cp -v .build/release/QRGen build/

clean:
	swift package clean
	rm -rf build/*

distclean: clean
	rm -rf Package.resolved
