// Central file for the renderer module.
#import "old.typ": render-old, old-renderer-setup

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
// 5. info needed by the renderer
// - renderer-ctx
//
// 6. Typst context
// - styles
#let render(ctx) = {
  // TODO: add new renderer, allow choosing.
  render-old(ctx)
}

// Sets up the renderer and generates the table.
// Call with:
// renderer-setup((renderer-ctx, size, styles) => ... code to generate the tablex table ...)
#let renderer-setup(tablex-callback) = {
  // TODO: add new renderer, allow choosing
  old-renderer-setup(tablex-callback)
}
