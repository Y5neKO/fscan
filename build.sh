#!/usr/bin/env bash
# ============================================================
#  编译脚本 — macOS / Linux / Windows EXE / Windows DLL
#  用法: ./build.sh [all|exe|dll|clean]
#  默认: all
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# ---- 配置 ----
DIST_DIR="dist"
LDFLAGS="-s -w"
MAIN_EXE="main.go"
MAIN_DLL="dll/main.go"
MAIN_EXE_BAK=".main_exe_bak.go"
LOADER_C="dll/loader.c"

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ok()   { echo -e "${GREEN}[OK]${NC} $1"; }
fail() { echo -e "${RED}[FAIL]${NC} $1"; }
info() { echo -e "${YELLOW}[..]${NC} $1"; }

# ---- 前置检查 ----
check_deps() {
    local missing=()
    command -v go        >/dev/null 2>&1 || missing+=("go")
    command -v x86_64-w64-mingw32-gcc >/dev/null 2>&1 || missing+=("x86_64-w64-mingw32-gcc")
    if [ ${#missing[@]} -gt 0 ]; then
        fail "缺少依赖: ${missing[*]}"
        fail "安装: brew install go mingw-w64"
        exit 1
    fi
    ok "依赖检查通过"
}

# ---- 清理 ----
do_clean() {
    info "清理 $DIST_DIR"
    rm -rf "$DIST_DIR"
    ok "已清理"
}

# ---- 恢复 EXE 入口 ----
restore_exe_main() {
    if [ -f "$MAIN_EXE_BAK" ]; then
        mv "$MAIN_EXE_BAK" "$MAIN_EXE"
    fi
}

# ---- 编译 EXE ----
build_exe() {
    check_deps

    # 确保 main.go 是 EXE 版本
    restore_exe_main

    mkdir -p "$DIST_DIR"/{darwin,linux,windows}

    # macOS (当前平台)
    info "编译 macOS (darwin/arm64)"
    GOOS=darwin GOARCH=arm64 go build -trimpath -ldflags "$LDFLAGS" -o "$DIST_DIR/darwin/fscan"
    ok "darwin/arm64"

    # Linux amd64
    info "编译 Linux (amd64)"
    GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -trimpath -ldflags "$LDFLAGS" -o "$DIST_DIR/linux/fscan"
    ok "linux/amd64"

    # Windows amd64
    info "编译 Windows EXE (amd64)"
    GOOS=windows GOARCH=amd64 CGO_ENABLED=0 go build -trimpath -ldflags "$LDFLAGS" -o "$DIST_DIR/windows/fscan.exe"
    ok "windows/amd64"
}

# ---- 编译 DLL ----
build_dll() {
    check_deps

    if [ ! -f "$MAIN_DLL" ] || [ ! -f "$LOADER_C" ]; then
        fail "缺少 DLL 源文件: dll/main.go 或 dll/loader.c"
        exit 1
    fi

    # 备份 EXE 版 main.go，替换为 DLL 版
    if [ -f "$MAIN_EXE" ]; then
        mv "$MAIN_EXE" "$MAIN_EXE_BAK"
    fi
    cp "$MAIN_DLL" "$MAIN_EXE"

    mkdir -p "$DIST_DIR/windows-dll"

    # 编译 DLL
    info "编译 Windows DLL (amd64, c-shared)"
    if CGO_ENABLED=1 GOOS=windows GOARCH=amd64 \
        CC=x86_64-w64-mingw32-gcc \
        go build -buildmode=c-shared -trimpath -ldflags "$LDFLAGS" -o "$DIST_DIR/windows-dll/fscan.dll"; then
        ok "fscan.dll"
    else
        fail "fscan.dll 编译失败"
        restore_exe_main
        exit 1
    fi

    # 编译 C 加载器
    info "编译 loader.exe"
    if x86_64-w64-mingw32-gcc -o "$DIST_DIR/windows-dll/loader.exe" "$LOADER_C" -s; then
        ok "loader.exe"
    else
        fail "loader.exe 编译失败"
        restore_exe_main
        exit 1
    fi

    # 删除自动生成的 .h 文件（不需要分发）
    rm -f "$DIST_DIR/windows-dll/fscan.h"

    # 恢复 EXE 版 main.go
    restore_exe_main
}

# ---- 用法 ----
usage() {
    echo "用法: $0 [all|exe|dll|clean]"
    echo ""
    echo "  all   编译全部 (默认)"
    echo "  exe   仅编译 EXE (darwin/linux/windows)"
    echo "  dll   仅编译 DLL + loader"
    echo "  clean 清理 dist 目录"
}

# ---- 主入口 ----
case "${1:-all}" in
    exe)   do_clean; build_exe ;;
    dll)   do_clean; build_dll ;;
    clean) do_clean ;;
    all)   do_clean; build_exe; echo ""; build_dll ;;
    *)     usage; exit 1 ;;
esac

echo ""
ok "编译完成，产物在 $DIST_DIR/"
echo ""
find "$DIST_DIR" -type f -exec ls -lh {} \;
