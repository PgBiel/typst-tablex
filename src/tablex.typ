// #10
// The tablex function, which is the entry point for the library.

// -- tablex imports --
#import "common.typ": *
#import "types.typ": *
#import "type-validators.typ": *
#import "utilities.typ": *
#import "grid.typ": *
#import "col-row-size.typ": *
#import "main-functions.typ": *
#import "option-parsing.typ": *
#import "renderer/renderer.typ": render
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
// Takes (row_num, cell_array) and returns
// the modified cell_array. Note that, here, they
// cannot be sent to another row. Also, cells may be
// 'none' if they're a position taken by a cell in a
// colspan/rowspan.
//
// map-cols: Maps each column of cells.
// Takes (col_num, cell_array) and returns
// the modified cell_array. Note that, here, they
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
    _tablex-table-counter.step()

    get-page-dim-writer()  // get the current page's dimensions

    let header-rows = validate-header-rows(header-rows)
    let repeat-header = validate-repeat-header(repeat-header, header-rows: header-rows)
    let header-hlines-have-priority = validate-header-hlines-priority(header-hlines-have-priority)
    let map-cells = parse-map-func(map-cells)
    let map-hlines = parse-map-func(map-hlines)
    let map-vlines = parse-map-func(map-vlines)
    let map-rows = parse-map-func(map-rows, uses-second-param: true)
    let map-cols = parse-map-func(map-cols, uses-second-param: true)

    layout(size => locate(t_loc => style(styles => {
        let table_id = _tablex-table-counter.at(t_loc)
        let page_dimensions = get-page-dim-state(table_id)
        let page_dim_at = page_dimensions.final(t_loc)
        let t_pos = t_loc.position()

        // Subtract the max width/height from current width/height to disregard margin/etc.
        let page_width = size.width
        let page_height = size.height

        let max_pos = default-if-none(page_dim_at.bottom_right, (x: t_pos.x + page_width, y: t_pos.y + page_height))
        let min_pos = default-if-none(page_dim_at.top_left, t_pos)

        let items = items.pos().map(table-item-convert)

        let gutter = parse-gutters(
            col-gutter: column-gutter, row-gutter: row-gutter,
            gutter: gutter,
            styles: styles,
            page-width: page_width, page-height: page_height
        )

        let validated_cols_rows = validate-cols-rows(
            columns, rows, items: items.filter(is-tablex-cell))

        let columns = validated_cols_rows.columns
        let rows = validated_cols_rows.rows
        items += validated_cols_rows.items

        let col_len = columns.len()
        let row_len = rows.len()

        // generate cell matrix and other things
        let grid_info = generate-grid(
            items,
            x_limit: col_len, y_limit: row_len,
            map-cells: map-cells
        )

        let table_grid = grid_info.grid
        let hlines = grid_info.hlines
        let vlines = grid_info.vlines
        let items = grid_info.items

        for _ in range(grid_info.new_row_count - row_len) {
            rows.push(auto)  // add new rows (due to extra cells)
        }

        let col_len = columns.len()
        let row_len = rows.len()

        let auto_lines_res = generate-autolines(
            auto-lines: auto-lines, auto-hlines: auto-hlines,
            auto-vlines: auto-vlines,
            hlines: hlines,
            vlines: vlines,
            col_len: col_len,
            row_len: row_len
        )

        hlines += auto_lines_res.new_hlines
        vlines += auto_lines_res.new_vlines

        let parsed_lines = _parse-lines(hlines, vlines, styles: styles, page-width: page_width, page-height: page_height)
        hlines = parsed_lines.hlines
        vlines = parsed_lines.vlines

        let mapped_grid = apply-maps(
            grid: table_grid,
            hlines: hlines,
            vlines: vlines,
            map-hlines: map-hlines,
            map-vlines: map-vlines,
            map-rows: map-rows,
            map-cols: map-cols
        )

        table_grid = mapped_grid.grid
        hlines = mapped_grid.hlines
        vlines = mapped_grid.vlines

        // re-parse just in case
        let parsed_lines = _parse-lines(hlines, vlines, styles: styles, page-width: page_width, page-height: page_height)
        hlines = parsed_lines.hlines
        vlines = parsed_lines.vlines

        // convert auto to actual size
        let updated_cols_rows = determine-auto-column-row-sizes(
            grid: table_grid,
            page_width: page_width, page_height: page_height,
            styles: styles,
            columns: columns, rows: rows,
            inset: inset, align: align,
            gutter: gutter
        )

        let columns = updated_cols_rows.columns
        let rows = updated_cols_rows.rows
        let gutter = updated_cols_rows.gutter

        let context = (
            // cell info and data
            grid: table_grid,
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
            // layout info
            min-pos: min_pos,
            max-pos: max_pos,
            // Typst context
            styles: styles,
            table-loc: t_loc,
            table-id: table_id
        )

        render(context)
    })))
}

// Same as table but defaults to lines off
#let gridx(..options) = {
    tablex(auto-lines: false, ..options)
}
