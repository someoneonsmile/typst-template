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

# 导出自包含单文件：just export [文书关键词] [输出文件]
export file="" out="":
    @target=$(./scripts/pick.sh "{{file}}") && \
    if [ -z "{{out}}" ]; then out="out/$(basename "$target" .typ).typ"; else out="{{out}}"; fi && \
    ./scripts/export.sh "$target" "$out"

# 编译所有文书
all:
    mkdir -p out
    find src/business -path '*/template/*.typ' -print | while read -r f; do typst compile --root . "$f" "out/$(basename "$f" .typ).pdf"; done
