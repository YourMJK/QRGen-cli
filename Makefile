.PHONY: build distclean

destination = build

build:
	swift build --configuration release && \
	mkdir -p $(destination) && \
	cp -v .build/release/QRGen-cli $(destination)/QRGen

clean:
	swift package clean
	rm -rf $(destination)/*

distclean: clean
	rm -rf Package.resolved
