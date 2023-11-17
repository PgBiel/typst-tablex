// Central file for the renderer module.
#import "old.typ": render-old

// ctx: The context dictionary with the following attributes:
//
// 1. cell info and data
// - grid
// - columns
// - rows
//
// 2. table parameters and styles
// - fill
// - align
// - stroke
// - inset
// - rtl
// - gutter
//
// 3. headers
// - repeat-header
// - header-hlines-have-priority
// - header-rows
//
// 4. lines
// - hlines
// - vlines
//
// 5. layout info
// - min-pos
// - max-pos
//
// 6. Typst context
// - styles
// - table-loc
// - table-id
#let render(ctx) = {
  // TODO: add new renderer, allow choosing.
  render-old(ctx)
}
