#!/usr/bin/env bash
set -euo pipefail

BUILD_DIR="build"
TIMER_NO_PAUSE="ON"

usage(){
    echo "Usage: $0 [clean] [timer-on|timer-off]"
    echo "  (no args)  : incremental build, timer no pause = ON"
    echo "  clean      : remove build dir then configure & build"
    echo "  timer-on   : build with RP2040_DEBUG_TIMER_NO_PAUSE=ON"
    echo "  timer-off  : build with RP2040_DEBUG_TIMER_NO_PAUSE=OFF"
    echo ""
    echo "Examples:"
    echo "  $0"
    echo "  $0 clean"
    echo "  $0 timer-off"
    echo "  $0 clean timer-on"
}

for arg in "$@"; do
    case "$arg" in
        -h|--help)
            usage
            exit 0
            ;;
        clean)
            rm -rf "$BUILD_DIR"
            ;;
        timer-on)
            TIMER_NO_PAUSE="ON"
            ;;
        timer-off)
            TIMER_NO_PAUSE="OFF"
            ;;
        *)
            echo "Unknown arg: $arg"
            usage
            exit 1
            ;;
    esac
done

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

cmake .. \
    -DRP2040_DEBUG_TIMER_NO_PAUSE="${TIMER_NO_PAUSE}"

make -j"$(nproc)"