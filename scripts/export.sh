#!/usr/bin/env bash
# 把一份文书及其 import 的项目内组件展开成一个自包含的单文件 .typ。
# 用法：scripts/export.sh <文书路径> <输出文件>
set -euo pipefail

if [[ $# -ne 2 ]]; then
    echo "用法：$0 <文书路径> <输出文件>" >&2
    exit 1
fi

target="$1"
out="$2"
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# just 配方里的引号会阻止 shell 展开 ~，这里补上
case "$out" in
    "~") out="$HOME" ;;
    "~/"*) out="$HOME/${out#\~/}" ;;
esac

# 统一成项目根相对路径（/src/...），与文书里的 import 写法一致
case "$target" in
    "$root"/*) rel="/${target#"$root"/}" ;;
    /*) echo "文书必须位于项目目录内：$target" >&2; exit 1 ;;
    *) rel="/${target#./}" ;;
esac

if [[ ! -f "$root$rel" ]]; then
    echo "找不到文书：$target" >&2
    exit 1
fi

files=()
seen=()

# 递归收集依赖；后序保证被依赖的文件排在前面
collect() {
    local rel="$1" dep s
    for s in "${seen[@]:-}"; do
        [[ "$s" == "$rel" ]] && return 0
    done
    seen+=("$rel")

    while IFS= read -r dep; do
        if [[ "$dep" == *.typ ]]; then
            if [[ ! -f "$root$dep" ]]; then
                echo "缺少依赖：$dep（被 ${rel#/} 引用）" >&2
                exit 1
            fi
            collect "$dep"
        fi
    done < <(grep -oE '^[[:space:]]*#import[[:space:]]+"/[^"]+"' "$root$rel" 2>/dev/null \
        | sed -E 's/^[[:space:]]*#import[[:space:]]+"([^"]+)"/\1/')

    files+=("$rel")
}

collect "$rel"

mkdir -p "$(dirname "$out")"
out_abs="$(cd "$(dirname "$out")" && pwd)/$(basename "$out")"
if [[ "$out_abs" == "$root$rel" ]]; then
    echo "输出文件不能覆盖源文书：$out" >&2
    exit 1
fi
{
    echo "// 本文件由 scripts/export.sh 从项目内文书导出，自包含，可脱离项目单独编译。"
    echo "// 源文件：${rel#/}"
    echo "// 重新导出：just export $(basename "$rel" .typ)"
    echo
    for f in "${files[@]}"; do
        echo "// ─────────────────────────── ${f#/} ───────────────────────────"
        # 项目内 import 已内联，删除；保留将来可能出现的外部包 import
        grep -vE '^[[:space:]]*#import[[:space:]]+"/' "$root$f" || true
        echo
    done
} > "$out"

echo "已导出：$out"
