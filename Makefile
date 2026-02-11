.PHONY: build test run clean lint

build:
	swift build

test:
	swift test

run:
	swift run SayToIt

clean:
	swift package clean
	rm -rf .build

lint:
	@if command -v swiftlint >/dev/null 2>&1; then \
		swiftlint; \
	else \
		echo "SwiftLint not installed. Install with: brew install swiftlint"; \
	fi
