#!/usr/bin/env bash
# 把文书名关键词解析为具体路径；没有关键词或多份匹配时用 fzf 交互选择。
set -euo pipefail

query="${1:-}"

# 已经是存在的文件：直接使用
if [[ -n "$query" && -f "$query" ]]; then
    printf '%s\n' "$query"
    exit 0
fi

# 收集所有文书
files=()
while IFS= read -r f; do
    if [[ "$f" == */template/*.typ ]]; then
        files+=("$f")
    fi
done < <(fd --type f --extension typ . business | sort)

if [[ ${#files[@]} -eq 0 ]]; then
    echo "business/ 下没有找到任何 .typ 文书" >&2
    exit 1
fi

# 用 fzf 选择；没有可用终端时返回失败
choose() {
    { exec 3<>/dev/tty; } 2>/dev/null || return 1
    exec 3>&-
    local selected
    selected=$(printf '%s\n' "$@" | fzf --prompt='选择文书 > ' --height=40% --reverse) || return 1
    if [[ -z "$selected" ]]; then
        return 1
    fi
    printf '%s\n' "$selected"
}

# 没有关键词：直接让用户从全部文书中选择
if [[ -z "$query" ]]; then
    if ! choose "${files[@]}"; then
        echo "未选择文书。候选：" >&2
        printf '  %s\n' "${files[@]}" >&2
        exit 1
    fi
    exit 0
fi

key="${query%.typ}"
[[ -n "$key" ]] || key="$query"

matches=()
while IFS= read -r f; do
    matches+=("$f")
done < <(printf '%s\n' "${files[@]}" | fzf --filter="$key")

if [[ ${#matches[@]} -eq 0 ]]; then
    echo "未找到匹配「$query」的文书。全部文书：" >&2
    printf '  %s\n' "${files[@]}" >&2
    exit 1
elif [[ ${#matches[@]} -eq 1 ]]; then
    printf '%s\n' "${matches[0]}"
else
    if ! choose "${matches[@]}"; then
        echo "未选择文书。候选：" >&2
        printf '  %s\n' "${matches[@]}" >&2
        exit 1
    fi
fi
