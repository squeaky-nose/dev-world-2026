# Build/run workflow for the two-trie Kotlin+Swift interop demo.
#
# One JVM process hosts both tries: `AvlTrie` runs natively in Kotlin, and
# `SwiftAVLTrie` runs in-process as a Swift dylib loaded via swift-java's
# jextract FFM bindings (see README -> Architecture). `make build` compiles
# both -- the Swift half first (via SwiftPM), which also *generates* the Java
# bindings the Kotlin half compiles against -- so there is no separate
# "build swift" / "build kotlin" split from the caller's perspective.

# swift-java (github.com/swiftlang/swift-java) is pre-1.0 with no source
# stability guarantee, so this project vendors + pins an exact commit rather
# than tracking main or a moving Maven Central release. See README ->
# Versions for why this specific commit.
SWIFT_JAVA_REPO := https://github.com/swiftlang/swift-java.git
SWIFT_JAVA_COMMIT := 2dd2c6043f63d0d2cd99dfdcc8f058949f0309f3
VENDOR_DIR := vendor/swift-java

WORDS ?= ospd.txt

.PHONY: all help setup build run clean distclean

all: help

help:
	@echo "Available targets:"
	@echo "  make setup        clone+pin vendor/swift-java and publish its Swift/JVM interop libraries to ~/.m2 (one-time; re-run after 'make distclean')"
	@echo "  make build        compile the Swift trie dylib, generate+compile its Java bindings, and compile the Kotlin app"
	@echo "  make run          build (if needed) and run interactively; WORDS=<path> selects the word list (default: ospd.txt)"
	@echo "  make clean        remove Kotlin/Swift build artifacts (keeps vendor/swift-java and ~/.m2)"
	@echo "  make distclean    clean, plus remove vendor/swift-java (forces 'make setup' to re-clone+re-publish)"

# Idempotent: skips the clone if vendor/swift-java already exists, so re-running
# after a partial failure (e.g. Gradle publish died) just retries the publish.
setup:
	@if [ ! -d "$(VENDOR_DIR)/.git" ]; then \
		echo "Cloning swift-java @ $(SWIFT_JAVA_COMMIT)..."; \
		git clone "$(SWIFT_JAVA_REPO)" "$(VENDOR_DIR)"; \
		git -C "$(VENDOR_DIR)" checkout "$(SWIFT_JAVA_COMMIT)"; \
	else \
		echo "vendor/swift-java already present, skipping clone (run 'make distclean' first to re-pin)."; \
	fi
	@echo "Publishing swift-java's Swift/JVM interop libraries to ~/.m2..."
	@cd "$(VENDOR_DIR)" && ./gradlew publishToMavenLocal

# installDist (not plain `gradle run`) so the run target below can invoke the
# generated launcher script directly: Gradle's `run` task doesn't forward the
# calling shell's stdin to the forked JVM by default, which breaks the
# interactive query loop when input is piped in.
build:
	@if [ ! -d "$(VENDOR_DIR)" ]; then \
		echo "error: $(VENDOR_DIR) not found -- run 'make setup' first" >&2; \
		exit 1; \
	fi
	./gradlew :app:installDist

run: build
	@echo "Using word list: $(WORDS)"
	kotlin/app/build/install/app/bin/app "$(WORDS)"

clean:
	./gradlew clean
	rm -rf swift/JvmLoveTrie/.build

distclean: clean
	rm -rf "$(VENDOR_DIR)"
