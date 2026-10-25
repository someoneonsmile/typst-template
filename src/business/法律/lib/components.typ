// 法律领域共用组件。
#import "/src/lib/spacing.typ": adaptive-gap
#import "/src/business/法律/lib/layout.typ": heiti

// 当事人信息行（顶格）
#let 当事人(标签, 内容) = {
  [#标签：#内容]
}

// 请求事项：编号列表
#let 请求事项(body) = block[
  #set enum(numbering: "1.", indent: 2em, body-indent: 0.5em)
  #body
]

// 此致：机关名称与正文底部自适应对齐
#let 此致(机关) = adaptive-gap(min-gap: 0pt, max-gap: 2.5em, block(breakable: false)[
  #set par(first-line-indent: 0pt)
  #h(2em)此致\
  #机关
])

// 落款：申请人、日期留空时保留手写或盖章位置
#let 落款(申请人: none, 日期: none) = adaptive-gap(min-gap: 1em, max-gap: 1.5em, block(breakable: false, width: 100%)[
  #set par(first-line-indent: 0pt)
  #set align(right)
  申请人：#if 申请人 == none { h(7em) } else { 申请人 }\
  日期：#if 日期 == none { [#h(2.6em)年#h(1.2em)月#h(1.2em)日] } else { 日期 }
])

// 附件：编号列表；标签固定黑体
#let 附件(body) = adaptive-gap(min-gap: 0em, max-gap: 2em, block(breakable: false)[
  #set par(first-line-indent: 0pt)
  #set enum(numbering: "1.", indent: 0em, body-indent: 0.5em)
  #text(font: heiti)[附：]
  #v(0.35em)
  #body
])
