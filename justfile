# 编译单份文书：just build 文件
build file:
    mkdir -p out
    typst compile --root . {{file}} "out/$(basename "{{file}}" .typ).pdf"

# 监听单份文书：just watch 文件
watch file:
    mkdir -p out
    typst watch --root . {{file}} "out/$(basename "{{file}}" .typ).pdf"

# 编译所有文书
all:
    mkdir -p out
    find business -path '*/template/*.typ' -print | while read -r f; do typst compile --root . "$f" "out/$(basename "$f" .typ).pdf"; done
