# 法律文书模板

基于 [Typst](https://typst.app) 的中文法律文书模板库。

## 结构

```
lib/                          业务无关的功能组件
business/lib/                 全业务通用的业务组件
business/法律/
├── lib/                      领域共用的版式、字体与组件
└── template/                 具体文书
```

约定：

- `lib/` 放代码，`template/` 放文书，两者可以出现在任意层级；
- 中文只用于业务名词（领域、分类、文书名、组件函数名），其余用英文；
- 跨层 `import` 一律用根相对路径（以 `/` 开头），编译时必须带 `--root .`。

## 依赖

- Typst 0.15+
- [just](https://github.com/casey/just)、[fd](https://github.com/sharkdp/fd)、[fzf](https://github.com/junegunn/fzf)
- 字体：FangSong（仿宋）、SimHei（黑体）。macOS 可在 `business/法律/lib/layout.typ` 中改成 `STFangsong` / `Heiti SC`。

## 使用

```bash
just build            # 不带关键词时用 fzf 选择文书
just build 追加        # 按关键词编译文书到 out/
just watch 追加        # 按关键词监听文书
just all              # 编译所有 template/ 下的文书
```

关键词按 fzf 的模糊规则匹配 `business/**/template/*.typ`，只输部分文件名即可；
不输关键词时直接弹出全部文书供选择，命中多份时也会弹出列表，也可以直接传入完整路径。

产物写入 `out/`，不纳入版本控制；该目录由构建命令自动创建。

## 新建文书

复制 `business/法律/template/` 下的文书，改文件名，替换顶部的「案件信息」和正文。

## 新建分类

在领域目录下按同样结构建立：

```
business/法律/执行/
├── lib/          # 仅执行类需要的版式或组件（可选）
└── template/     # 执行类文书
```

如果分类有自己的版式，把文书里的

```typst
#import "/business/法律/lib/layout.typ": document-layout
```

改成

```typst
#import "/business/法律/执行/lib/layout.typ": document-layout
```

法律领域组件（当事人、请求事项、此致、落款、附件）从
`/business/法律/lib/components.typ` 引入，业务通用组件从
`/business/lib/components.typ` 引入。
