// Central file for the renderer module.
#import "old.typ": render-old, old-renderer-setup
#import "cetz.typ": render-cetz, cetz-renderer-setup

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
#let render(renderer, ctx) = {
  // TODO: add new renderer.
  if renderer == "old" {
    render-old(ctx)
  } else if renderer == "cetz" {
    render-cetz(ctx)
  } else {
    panic("Internal tablex error: Renderer must be 'old' or 'cetz'.")
  }
}

// Sets up the renderer and generates the table.
// Call with:
// renderer-setup(renderer, renderer-args, (renderer-ctx, size, styles) => ... code to generate the tablex table ...)
#let renderer-setup(renderer, renderer-args, tablex-callback) = {
  // TODO: add new renderer.
  if renderer == "old" {
    old-renderer-setup(tablex-callback)
  } else if renderer == "cetz" {
    cetz-renderer-setup(renderer-args, tablex-callback)
  } else {
    panic("Internal tablex error: Renderer must be 'old' or 'cetz'.")
  }
}
