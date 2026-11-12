#!/bin/sh
# Download (when needed), configure, and build Artpol ZipArchive for b1gZIP.
set -eu

ZIPARCHIVE_URL='https://www.artpol-software.com/Downloads/ziparchive_src.zip'
WORK_DIR=''
SOURCE_DIR=''

for arg in "$@"; do
    case "$arg" in
        --work-dir=*) WORK_DIR=${arg#*=} ;;
        --source-dir=*) SOURCE_DIR=${arg#*=} ;;
        *) echo "Unknown argument: $arg" >&2; exit 2 ;;
    esac
done

if [ -z "$WORK_DIR" ]; then
    echo "Usage: $0 --work-dir=DIR [--source-dir=DIR]" >&2
    exit 2
fi

mkdir -p "$WORK_DIR"

if [ -z "$SOURCE_DIR" ]; then
    ARCHIVE="$WORK_DIR/ziparchive_src.zip"
    EXTRACT_DIR="$WORK_DIR/source"
    if [ ! -s "$ARCHIVE" ]; then
        if command -v curl >/dev/null 2>&1; then
            curl -fL "$ZIPARCHIVE_URL" -o "$ARCHIVE"
        elif command -v wget >/dev/null 2>&1; then
            wget -O "$ARCHIVE" "$ZIPARCHIVE_URL"
        else
            echo "Install curl or wget to download $ZIPARCHIVE_URL" >&2
            exit 1
        fi
    fi
    if ! command -v unzip >/dev/null 2>&1; then
        echo "Install unzip to extract $ARCHIVE" >&2
        exit 1
    fi
    mkdir -p "$EXTRACT_DIR"
    unzip -oq "$ARCHIVE" -d "$EXTRACT_DIR"
    SEARCH_DIR="$EXTRACT_DIR"
else
    SEARCH_DIR=$SOURCE_DIR
fi

if [ ! -d "$SEARCH_DIR" ]; then
    echo "ZipArchive source directory does not exist: $SEARCH_DIR" >&2
    exit 1
fi

# Prefer the archive's top-level CMake project. Its nested ZipArchive
# CMakeLists.txt expects PROJECT_VERSION from the parent project.
if [ -f "$SEARCH_DIR/CMakeLists.txt" ]; then
    SOURCE_ROOT=$SEARCH_DIR
else
    CMAKE_FILE=$(find "$SEARCH_DIR" -type f -name CMakeLists.txt -print -quit)
    if [ -z "$CMAKE_FILE" ]; then
        echo "No CMakeLists.txt found under $SEARCH_DIR" >&2
        exit 1
    fi
    SOURCE_ROOT=$(dirname "$CMAKE_FILE")
fi
SOURCE_ROOT=$(CDPATH= cd -- "$SOURCE_ROOT" && pwd -P)

HEADER=$(find "$SOURCE_ROOT" -type f -name ZipArchive.h -print -quit)
if [ -z "$HEADER" ]; then
    echo "ZipArchive.h not found under $SOURCE_ROOT" >&2
    exit 1
fi
INCLUDE_DIR=$(dirname "$HEADER")
BUILD_DIR="$WORK_DIR/build"

# CMake refuses to reuse a build tree when its source directory changes.
# This can happen when an earlier configure selected the nested CMakeLists.txt
# and a newer run correctly selects the top-level project. Discard only that
# stale CMake build tree; keep the downloaded archive and extracted sources.
if [ -f "$BUILD_DIR/CMakeCache.txt" ]; then
    CACHED_SOURCE=$(sed -n 's/^CMAKE_HOME_DIRECTORY:INTERNAL=//p' "$BUILD_DIR/CMakeCache.txt" | head -n 1)
    if [ -n "$CACHED_SOURCE" ] && [ "$CACHED_SOURCE" != "$SOURCE_ROOT" ]; then
        echo "CMake source directory changed; removing stale build directory $BUILD_DIR"
        rm -rf "$BUILD_DIR"
    fi
fi

cmake -S "$SOURCE_ROOT" -B "$BUILD_DIR" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -DZIP_ENABLE_UNICODE=ON \
    -DZIP_ENABLE_ZIP64=ON
cmake --build "$BUILD_DIR" --config Release

LIBRARY=$(find "$SOURCE_ROOT" "$BUILD_DIR" -type f -name libZipArchive.a -print -quit)
if [ -z "$LIBRARY" ]; then
    echo "CMake completed but libZipArchive.a was not found under $SOURCE_ROOT or $BUILD_DIR" >&2
    exit 1
fi

printf '%s\n' "$INCLUDE_DIR" > "$WORK_DIR/include-dir.txt"
printf '%s\n' "$(dirname "$LIBRARY")" > "$WORK_DIR/library-dir.txt"
echo "Built $LIBRARY"
