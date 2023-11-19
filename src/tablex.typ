// #10
// The tablex function, which is the entry point for the library.

// -- tablex imports --
#import "common.typ": *
#import "types.typ": *
#import "type-validators.typ": *
#import "utilities.typ": *
#import "grid.typ": *
#import "col-row-size.typ": *
#import "option-parsing.typ": *
#import "renderer/renderer.typ": render, renderer-setup
// -- end imports --

// Creates a table.
//
// OPTIONS:
// columns: table column sizes (array of sizes,
// or a single size for 1 column)
//
// rows: row sizes (same format as columns)
//
// align: how to align cells (alignment, array of alignments
// (one for each column), or a function
// (col, row) => alignment)
//
// items: The table items, as specified by the columns
// and rows. Can also be cellx, hlinex and vlinex objects.
//
// fill: how to fill cells (color/none, array of colors
// (one for each column), or a function (col, row) => color)
//
// stroke: how to draw the table lines (stroke)
// column-gutter: optional separation (length) between columns
// row-gutter: optional separation (length) between rows
// gutter: quickly apply a length to both column- and row-gutter
//
// repeat-header: true = repeat the first row (or rowspan)
// on all pages; integer = repeat for the first n pages;
// array of integers = repeat on exactly those pages
// (where 1 is the first, so ignored); false = do not repeat
// the first row group (default).
//
// header-rows: minimum amount of rows for the repeatable
// header. 1 by default. Automatically increases if
// one of the cells is a rowspan that would go beyond the
// given amount of rows. For example, if 3 is given,
// then at least the first 3 rows will repeat.
//
// header-hlines-have-priority: if true, the horizontal
// lines below the header being repeated take priority
// over the rows they appear atop of on further pages.
// If false, they draw their own horizontal lines.
// Defaults to true.
//
// rtl: if true, the table is horizontally flipped.
// That is, cells and lines are placed in the opposite order
// (starting from the right), and horizontal lines are flipped.
// This is meant to simulate the behavior of default Typst tables when
// 'set text(dir: rtl)' is used, and is useful when writing in a language
// with a RTL (right-to-left) script.
// Defaults to false.
//
// auto-lines: true = applies true to both auto-hlines and
// auto-vlines; false = applies false to both.
// Their values override this one unless they are 'auto'.
//
// auto-hlines: true = draw a horizontal line on every line
// without a manual horizontal line specified; false = do
// not draw any horizontal line without manual specification.
// Defaults to 'auto' (follows 'auto-lines').
//
// auto-vlines: true = draw a vertical line on every column
// without a manual vertical line specified; false = requires
// manual specification. Defaults to 'auto' (follows
// 'auto-lines')
//
// map-cells: Takes a cellx and returns another cellx (or
// content).
//
// map-hlines: Takes each horizontal line (hlinex) and
// returns another.
//
// map-vlines: Takes each vertical line (vlinex) and
// returns another.
//
// map-rows: Maps each row of cells.
// Takes (row-num, cell-array) and returns
// the modified cell-array. Note that, here, they
// cannot be sent to another row. Also, cells may be
// 'none' if they're a position taken by a cell in a
// colspan/rowspan.
//
// map-cols: Maps each column of cells.
// Takes (col-num, cell-array) and returns
// the modified cell-array. Note that, here, they
// cannot be sent to another row. Also, cells may be
// 'none' if they're a position taken by a cell in a
// colspan/rowspan.
#let tablex(
    columns: auto, rows: auto,
    inset: 5pt,
    align: auto,
    fill: none,
    stroke: auto,
    column-gutter: auto, row-gutter: auto,
    gutter: none,
    repeat-header: false,
    header-rows: 1,
    header-hlines-have-priority: true,
    rtl: false,
    auto-lines: true,
    auto-hlines: auto,
    auto-vlines: auto,
    map-cells: none,
    map-hlines: none,
    map-vlines: none,
    map-rows: none,
    map-cols: none,
    ..items
) = {
    let header-rows = validate-header-rows(header-rows)
    let repeat-header = validate-repeat-header(repeat-header, header-rows: header-rows)
    let header-hlines-have-priority = validate-header-hlines-priority(header-hlines-have-priority)
    let map-cells = parse-map-func(map-cells)
    let map-hlines = parse-map-func(map-hlines)
    let map-vlines = parse-map-func(map-vlines)
    let map-rows = parse-map-func(map-rows, uses-second-param: true)
    let map-cols = parse-map-func(map-cols, uses-second-param: true)

    // --- initial grid setup (doesn't require renderer setup) ---
    let items = items.pos().map(table-item-convert)

    let validated-cols-rows = validate-cols-rows(columns, rows, items: items.filter(is-tablex-cell))

    let columns = validated-cols-rows.columns
    let rows = validated-cols-rows.rows
    items += validated-cols-rows.items

    let col-len = columns.len()
    let row-len = rows.len()

    // generate cell matrix and other things
    let grid-info = generate-grid(
        items,
        x-limit: col-len, y-limit: row-len,
        map-cells: map-cells
    )

    let table-grid = grid-info.grid
    let hlines = grid-info.hlines
    let vlines = grid-info.vlines
    let items = grid-info.items

    for _ in range(grid-info.new-row-count - row-len) {
        rows.push(auto)  // add new rows (due to extra cells)
    }

    let col-len = columns.len()
    let row-len = rows.len()

    let auto-lines-res = generate-autolines(
        auto-lines: auto-lines, auto-hlines: auto-hlines,
        auto-vlines: auto-vlines,
        hlines: hlines,
        vlines: vlines,
        col-len: col-len,
        row-len: row-len
    )

    hlines += auto-lines-res.new-hlines
    vlines += auto-lines-res.new-vlines
    // --- finish initial grid setup ---

    // Gather the info the renderer needs (available through renderer-ctx),
    // and also get the page/container's dimensions ('container-size')
    // and the current styles ('styles').
    renderer-setup((renderer-ctx, container-size, styles) => {
        let page-width = container-size.width
        let page-height = container-size.height

        let gutter = parse-gutters(
            col-gutter: column-gutter, row-gutter: row-gutter,
            gutter: gutter,
            styles: styles,
            page-width: page-width, page-height: page-height
        )

        let parsed-lines = _parse-lines(hlines, vlines, styles: styles, page-width: page-width, page-height: page-height)
        let hlines = parsed-lines.hlines
        let vlines = parsed-lines.vlines

        let mapped-grid = apply-maps(
            grid: table-grid,
            hlines: hlines,
            vlines: vlines,
            map-hlines: map-hlines,
            map-vlines: map-vlines,
            map-rows: map-rows,
            map-cols: map-cols
        )

        let table-grid = mapped-grid.grid
        let hlines = mapped-grid.hlines
        let vlines = mapped-grid.vlines

        // re-parse just in case
        let parsed-lines = _parse-lines(hlines, vlines, styles: styles, page-width: page-width, page-height: page-height)
        let hlines = parsed-lines.hlines
        let vlines = parsed-lines.vlines

        // convert auto to actual size
        let updated-cols-rows = determine-auto-column-row-sizes(
            grid: table-grid,
            page-width: page-width, page-height: page-height,
            styles: styles,
            columns: columns, rows: rows,
            inset: inset, align: align,
            gutter: gutter
        )

        let columns = updated-cols-rows.columns
        let rows = updated-cols-rows.rows
        let gutter = updated-cols-rows.gutter

        let context = (
            // cell info and data
            grid: table-grid,
            columns: columns,
            rows: rows,
            // table parameters and styles
            fill: fill,
            align: align,
            stroke: stroke,
            inset: inset,
            rtl: rtl,
            gutter: gutter,
            // headers
            repeat-header: repeat-header,
            header-hlines-have-priority: header-hlines-have-priority,
            header-rows: header-rows,
            // lines
            hlines: hlines,
            vlines: vlines,
            // renderer context info
            renderer-ctx: renderer-ctx,
            // Typst context
            styles: styles
        )

        render(context)
    })
}

// Same as table but defaults to lines off
#let gridx(..options) = {
    tablex(auto-lines: false, ..options)
}
