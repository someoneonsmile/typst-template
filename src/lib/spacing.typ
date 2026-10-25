// 自适应间距：在可用高度内尽量把内容推向页面底部，间距限制在 [min-gap, max-gap]。
// Typst 的 calc.clamp 不支持长度，这里用 min/max 组合代替。
#let adaptive-gap(body, max-gap: 3em, min-gap: 0pt) = layout(size => {
  let body-h = measure(body, width: size.width).height
  let max-h = measure(h(max-gap)).width
  let min-h = calc.min(measure(h(min-gap)).width, max-h)
  let gap = calc.min(max-h, calc.max(min-h, size.height - body-h))
  v(gap)
  body
})
