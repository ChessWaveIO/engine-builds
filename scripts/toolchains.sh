#!/usr/bin/env bash
set -euo pipefail

# Exports CC/CXX/AR/STRIP and platform triplets
use_toolchain() {
  local platform="$1"
  case "$platform" in
    linux-x86_64)
      export CC=gcc CXX=g++ AR=ar STRIP=strip
      export CFLAGS="-O3 -pipe" CXXFLAGS="-O3 -pipe"
      ;;
    linux-aarch64)
      export CC=aarch64-linux-gnu-gcc CXX=aarch64-linux-gnu-g++ AR=aarch64-linux-gnu-ar STRIP=aarch64-linux-gnu-strip
      export CFLAGS="-O3 -pipe" CXXFLAGS="-O3 -pipe"
      ;;
    windows-x86_64)
      export CC=x86_64-w64-mingw32-gcc CXX=x86_64-w64-mingw32-g++ AR=x86_64-w64-mingw32-ar STRIP=x86_64-w64-mingw32-strip
      export CFLAGS="-O3 -static -pipe" CXXFLAGS="-O3 -static -pipe"
      ;;
    macos-universal)
      # Build twice and lipo later; per-engine build script should respect this.
      export CC=clang CXX=clang++ AR=ar STRIP=strip
      export CFLAGS="-O3 -pipe" CXXFLAGS="-O3 -pipe"
      ;;
    *)
      echo "Unknown PLATFORM=$platform" >&2; exit 2;;
  esac
}

