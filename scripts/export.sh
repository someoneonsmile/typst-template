#!/usr/bin/env bash
# 导出文书及沿途各层的 GEN-AGENTS.md。
# 合并模式把依赖展开进单个 .typ；不合并模式保留文书的原始目录层级。
# 用法：scripts/export.sh <merged|unmerged> <文书路径> <输出目录>
set -euo pipefail

if [[ $# -ne 3 ]]; then
    echo "用法：$0 <merged|unmerged> <文书路径> <输出目录>" >&2
    exit 1
fi

mode="$1"
target="$2"
out_dir="$3"
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

case "$mode" in
    merged|unmerged) ;;
    *) echo "未知导出模式：$mode" >&2; exit 1 ;;
esac

# just 配方里的引号会阻止 shell 展开 ~，这里补上
case "$out_dir" in
    "~") out_dir="$HOME" ;;
    "~/"*) out_dir="$HOME/${out_dir#\~/}" ;;
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

# 收集源码中引用的项目内资源，保持原路径复制到导出目录。
asset_parts=()
for f in "${files[@]}"; do
    while IFS= read -r asset; do
        [[ -n "$asset" && "$asset" != *.typ && -f "$root$asset" ]] || continue
        exists=false
        for existing in "${asset_parts[@]:-}"; do
            if [[ "$existing" == "$asset" ]]; then
                exists=true
                break
            fi
        done
        [[ "$exists" == true ]] || asset_parts+=("$asset")
    done < <(grep -oE '"/[^"]+"' "$root$f" 2>/dev/null \
        | sed -E 's/^"(.*)"$/\1/')
done

mkdir -p "$out_dir"
out_dir_abs="$(cd "$out_dir" && pwd)"
stem="$(basename "$rel" .typ)"
merged_out="$out_dir_abs/$stem.typ"
unmerged_out="$out_dir_abs$rel"
if [[ "$merged_out" == "$root$rel" || "$unmerged_out" == "$root$rel" ]]; then
    echo "导出目录不能是源文书所在目录：$out_dir" >&2
    exit 1
fi

# 按目录层级收集 GEN-AGENTS.md，父层在前、子层在后。
agent_parts=()
target_dir="${rel%/*}"
if [[ "$target_dir" == /src/business/* || "$target_dir" == /src/business ]]; then
    current=""
    IFS='/' read -r -a target_parts <<< "${target_dir#/}"
    for part in "${target_parts[@]}"; do
        current="$current/$part"
        [[ "$current" == /src/business || "$current" == /src/business/* ]] || continue
        candidate="$root$current/GEN-AGENTS.md"
        if [[ -f "$candidate" ]]; then
            agent_parts+=("$candidate")
        fi
    done
fi

agent_out="$out_dir_abs/AGENTS.md"
if [[ "$agent_out" == "$root/AGENTS.md" ]]; then
    echo "输出目录不能是项目根目录，否则会覆盖项目级 AGENTS.md" >&2
    exit 1
fi
if [[ ${#agent_parts[@]} -gt 0 && -e "$agent_out" ]] \
    && ! head -n 1 "$agent_out" | grep -q '^<!-- 由 scripts/export.sh 生成 -->$'; then
    echo "目标目录已有非导出生成的 AGENTS.md，拒绝覆盖：$agent_out" >&2
    exit 1
fi

just_out="$out_dir_abs/justfile"
if [[ "$mode" == unmerged && -e "$just_out" ]] \
    && ! head -n 1 "$just_out" | grep -q '^# 由 scripts/export.sh 生成$'; then
    echo "目标目录已有非导出生成的 justfile，拒绝覆盖：$just_out" >&2
    exit 1
fi

if [[ "$mode" == merged ]]; then
    {
        echo "// 本文件由 scripts/export.sh 从项目内文书合并导出。"
        echo "// 源文件：${rel#/}"
        echo "// 重新导出：just export $(basename "$rel" .typ)"
        echo
        for f in "${files[@]}"; do
            echo "// ─────────────────────────── ${f#/} ───────────────────────────"
            # 项目内 import 已内联，删除；保留将来可能出现的外部包 import
            grep -vE '^[[:space:]]*#import[[:space:]]+"/' "$root$f" || true
            echo
        done
    } > "$merged_out"
else
    for f in "${files[@]}"; do
        dest="$out_dir_abs$f"
        [[ "$dest" == "$root$f" ]] && continue
        mkdir -p "$(dirname "$dest")"
        cp "$root$f" "$dest"
    done
    {
        echo "# 由 scripts/export.sh 生成"
        echo
        echo "build:"
        echo "    mkdir -p out"
        printf '    typst compile --root . "%s" "out/%s.pdf"\n' "${rel#/}" "$stem"
    } > "$just_out"
fi

if [[ ${#asset_parts[@]} -gt 0 ]]; then
    for f in "${asset_parts[@]}"; do
        dest="$out_dir_abs$f"
        [[ "$dest" == "$root$f" ]] && continue
        mkdir -p "$(dirname "$dest")"
        cp "$root$f" "$dest"
    done
fi

if [[ ${#agent_parts[@]} -gt 0 ]]; then
    {
        echo '<!-- 由 scripts/export.sh 生成 -->'
        echo
        for f in "${agent_parts[@]}"; do
            echo "<!-- 来源：${f#"$root"/} -->"
            cat "$f"
            echo
        done
    } > "$agent_out"
    echo "已生成：$agent_out"
fi

if [[ "$mode" == unmerged ]]; then
    echo "已生成：$just_out"
fi

if [[ "$mode" == merged ]]; then
    echo "已合并导出：$merged_out"
else
    echo "已复制导出：$out_dir_abs"
fi
