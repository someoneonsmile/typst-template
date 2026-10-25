// ─────────────────────────── 字体 ───────────────────────────
// 默认使用 Windows/Linux 常见的仿宋、黑体；macOS 可改为 "STFangsong" / "Heiti SC"。
#let fangsong = "FangSong"
#let heiti = "SimHei"

// ─────────────────────────── 版式 ───────────────────────────
// 用法：#show: document-layout.with(title: "文书标题")
#let document-layout(
  doc,
  title: none,
  margin: 2.5cm,
  页码: true,
) = {
  set document(title: title)

  set page(
    paper: "a4",
    margin: margin,
    numbering: none,
    footer: if 页码 {
      context [
        #set align(center)
        #set text(size: 9pt)
        #counter(page).display()
      ]
    },
  )

  set text(
    font: fangsong,
    size: 12pt,
    lang: "zh",
    region: "cn",
    cjk-latin-spacing: auto,
  )

  set par(
    justify: true,
    leading: 1.2em,
    spacing: 1.2em,
    first-line-indent: (amount: 2em, all: true),
  )

  // 仅三级标题有编号
  set heading(numbering: (..nums) => {
    let n = nums.pos()
    if n.len() == 3 { numbering("（一）", n.last()) }
  })

  // 一级标题：文书主标题
  show heading.where(level: 1): it => {
    set text(font: heiti, size: 18pt, weight: "bold")
    set align(center)
    set par(first-line-indent: 0pt)
    set block(above: 0pt, below: 1.5em, sticky: true)
    it
  }

  // 二级标题：主要章节
  show heading.where(level: 2): it => {
    set text(font: heiti, size: 14pt, weight: "bold")
    set align(left)
    set par(first-line-indent: 0pt)
    set block(above: 1.5em, below: 1.2em, sticky: true)
    it
  }

  // 三级标题：具体分项；用 block 包裹并设置 sticky，避免标题孤立在页尾
  show heading.where(level: 3): it => block(
    above: 1.2em,
    below: 1.2em,
    sticky: true,
    inset: (left: 2em),
  )[
    #set text(font: heiti, size: 12pt, weight: "bold")
    #set align(left)
    #set par(first-line-indent: 0pt)
    #set block(above: 0pt, below: 0pt)
    #it
  ]

  doc
}
