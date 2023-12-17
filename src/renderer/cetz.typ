#import "row-groups.typ": generate-row-groups
#import "../common.typ": _length-type, _array-type
#import "../type-validators.typ": is-tablex-hline, is-tablex-vline
#import "../col-row-size.typ": make-cell-box
#import "../width-height.typ": cell-width, cell-height, width-between, height-between
#import "../lines.typ": draw-hline, draw-vline

// Converts a length to an equivalent coordinate in CeTZ.
// For instance, 2cm becomes 2 if cetz-unit is 1cm (default).
#let convert-length-to-cetz-units(len, cetz-unit: 1cm) = {
  assert(type(len) == _length-type, message: "Tablex error: Cannot convert non-length to CeTZ units.")
  len / cetz-unit
}

#let convert-coords-to-cetz-units(x, y, cetz-unit: 1cm) = {
  assert(type(x) == _length-type and type(y) == _length-type, message: "Tablex error: Coordinates must be lengths.")

  // TODO: subtract from top left of table

  let x-cetz = convert-length-to-cetz-units(x, cetz-unit: cetz-unit)
  // IMPORTANT: y axis in CeTZ grows UP!
  let y-cetz = -convert-length-to-cetz-units(y, cetz-unit: cetz-unit)

  (x-cetz, y-cetz)
}

// Draws a cell in cetz.
// 'cell-box' contains the generated cell content box.
// Requires x, y, width, height in length units.
// x, y are relative to the table's (0pt, 0pt).
#let draw-cetz-cell(cetz-draw, cell, cell-box, x: none, y: none, width: none, height: none) = {
  assert(type(x) == _length-type and type(y) == _length-type, message: "Tablex error: Cell x and y must be lengths. Got: " + repr(x) + ", " + repr(y))
  assert(type(width) == _length-type and type(height) == _length-type, message: "Tablex error: Cell width and height must be lengths. Got: " + repr(width) + ", " + repr(height))

  // TODO: specify cetz unit different from 1cm
  let (x-cetz, y-cetz, width-cetz, height-cetz) = (x, y, width, height).map(convert-length-to-cetz-units)

  // TODO: subtract from top left (coords are relative to top left of table still)
  let top-left = convert-coords-to-cetz-units(x, y)
  let bottom-right = convert-coords-to-cetz-units(x + width, y + height)

  // TODO: customize prefix, or even allow a function
  let node-name = "tbx-" + str(cell.x) + "-" + str(cell.y)

  // cetz-draw.rect(top-left, bottom-right, fill: fill, stroke: none)
  cetz-draw.content(top-left, bottom-right, cell-box, name: node-name)
}

// Draws a line in cetz with the specified information.
#let draw-cetz-line(cetz-draw, _, start: none, end: none, stroke: auto) = {
  assert(type(start) == _array-type and type(end) == _array-type, message: "Start and end must be arrays.")
  assert((start + end).all(coord => type(coord) == _length-type), message: "Start and end must be arrays of lengths.")

  // TODO: allow user to configure cetz unit (1cm => ???)
  // or use CeTZ ctx or something
  let start-cetz = convert-coords-to-cetz-units(start.first(), start.at(1))
  let end-cetz = convert-coords-to-cetz-units(end.first(), end.at(1))
  let style-args = (:)
  if stroke != auto {
    style-args.stroke = stroke
  }

  // Draw a CeTZ line.
  cetz-draw.line(start-cetz, end-cetz, ..style-args)
}

// Sets up the CeTZ renderer, feeds its context to the table and outputs the table.
// Use as follows:
// cetz-renderer-setup(size, (renderer-ctx, size, styles) => ... tablex code ...)
#let cetz-renderer-setup(renderer-args, tablex-callback) = {
  // required
  let styles = renderer-args.at("styles")
  // TODO: figure out canvas size?
  // For now simulate (auto, auto)
  let infpt = float("inf") * 1pt
  let size = (width: infpt, height: infpt)

  tablex-callback((:), size, styles)
}

// Renders the table with the given context dictionary (see renderer.typ).
// Uses CeTZ as the renderer.
#let render-cetz(ctx) = {
  // Row groups are blocks of content which are either:
  // 1. A single row.
  // 2. Two or more rows spanned by a rowspan cell. Those rows must stay together (in the same page).
  // 3. Header rows, which must stay together (in the same page).
  let row-groups = generate-row-groups(ctx)

  // Provide context parameters to the functions we'll need
  let cell-width = cell-width.with(columns: ctx.columns, gutter: ctx.gutter)
  let cell-height = cell-height.with(rows: ctx.rows, gutter: ctx.gutter)
  let width-between = width-between.with(columns: ctx.columns, gutter: ctx.gutter)
  let height-between = height-between.with(rows: ctx.rows, gutter: ctx.gutter)

  import "@preview/cetz:0.1.2": canvas, draw

  // Provide 'draw' module to cetz functions
  let draw-cetz-line = draw-cetz-line.with(draw)
  let draw-cetz-cell = draw-cetz-cell.with(draw)

  // Use cetz functions to draw lines
  let draw-hline = draw-hline.with(columns: ctx.columns, rows: ctx.rows, stroke: ctx.stroke, gutter: ctx.gutter, vlines: ctx.vlines, styles: ctx.styles, line: draw-cetz-line)
  let draw-vline = draw-vline.with(columns: ctx.columns, rows: ctx.rows, stroke: ctx.stroke, gutter: ctx.gutter, hlines: ctx.hlines, styles: ctx.styles, line: draw-cetz-line)

  // Gather cells and lines from row groups
  let cells = row-groups.map(group => group.rows).flatten()
  let lines = (row-groups.map(group => group.hlines) + row-groups.map(group => group.vlines)).flatten()

  // Draw cells then lines
  for cell in cells {
    let x = width-between(start: 0, end: cell.x)  // TODO: RTL
    let y = height-between(start: 0, end: cell.y)  // TODO: RTL
    let width = cell-width(cell.x, colspan: cell.colspan)
    let height = cell-height(cell.y, rowspan: cell.rowspan)
    let cell-box = make-cell-box(
      cell,
      width: width,
      height: height,
      inset: ctx.inset,
      align-default: ctx.align,
      fill-default: ctx.fill)

    draw-cetz-cell(cell, cell-box, x: x, y: y, width: width, height: height)
  }

  for line in lines {
    if is-tablex-hline(line) {
      draw-hline(line)
    } else if is-tablex-vline(line) {
      draw-vline(line)
    } else {
      panic("Tablex internal error: Invalid line: " + repr(line))
    }
  }
}
