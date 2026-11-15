# 编译单份文书：just build [文件名关键词]
build file="":
    @target=$(./scripts/pick.sh "{{file}}") && \
    mkdir -p out && \
    typst compile --root . "$target" "out/$(basename "$target" .typ).pdf"

# 监听单份文书：just watch [文件名关键词]
watch file="":
    @target=$(./scripts/pick.sh "{{file}}") && \
    mkdir -p out && \
    typst watch --root . "$target" "out/$(basename "$target" .typ).pdf"

# 合并导出自包含单文件及 AGENTS.md：just export [文书关键词] [输出目录]
export file="" out="":
    @target=$(./scripts/pick.sh "{{file}}") && \
    if [ -z "{{out}}" ]; then out="out/$(basename "$target" .typ)"; else out="{{out}}"; fi && \
    ./scripts/export.sh merged "$target" "$out"

# 不合并导出文书、依赖源码及 AGENTS.md：just export-unmerged [文书关键词] [输出目录]
export-unmerged file="" out="":
    @target=$(./scripts/pick.sh "{{file}}") && \
    if [ -z "{{out}}" ]; then out="out/$(basename "$target" .typ)-unmerged"; else out="{{out}}"; fi && \
    ./scripts/export.sh unmerged "$target" "$out"

# 编译所有文书
all:
    mkdir -p out
    find src/business -path '*/template/*.typ' -print | while read -r f; do typst compile --root . "$f" "out/$(basename "$f" .typ).pdf"; done
