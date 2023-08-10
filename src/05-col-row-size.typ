// -- tablex imports --
#import "00-common.typ": *
#import "01-types.typ": *
#import "02-type-validators.typ": *
#import "03-utilities.typ": *
#import "04-grid.typ": *
// -- end imports --

// Makes a cell's box, using the given options
// cell - The cell data (including content)
// width, height - The cell's dimensions
// inset - The table's inset
// align_default - The default alignment if the cell doesn't specify one
// fill_default - The default fill color / etc if the cell doesn't specify one
#let make-cell-box(
        cell,
        width: 0pt, height: 0pt, inset: 5pt,
        align_default: left,
        fill_default: none) = {

    let align_default = if type(align_default) == "function" {
        align_default(cell.x, cell.y)  // column, row
    } else {
        align_default
    }

    let fill_default = if type(fill_default) == "function" {
        fill_default(cell.x, cell.y)  // row, column
    } else {
        fill_default
    }

    let content = cell.content

    let inset = default-if-auto(cell.inset, inset)

    // use default align (specified in
    // table 'align:')
    // when the cell align is 'auto'
    let cell_align = default-if-auto(cell.align, align_default)

    // same here for fill
    let cell_fill = default-if-auto(cell.fill, fill_default)

    if type(cell_fill) == "array" {
        let fill_len = cell_fill.len()

        if fill_len == 0 {
            // no fill values specified
            // => no fill
            cell_fill = none
        } else if cell.x == auto {
            // for some reason the cell x wasn't yet
            // determined => just take the last
            // fill value
            cell_fill = cell_fill.last()
        } else {
            // use mod to make the fill value pattern
            // repeat if there are more columns than
            // fill values.
            cell_fill = cell_fill.at(calc-mod(cell.x, fill_len))
        }
    }

    if cell_fill != none and type(cell_fill) != "color" {
        panic("Tablex error: Invalid fill specified (must be either a function (column, row) -> fill, a color, an array of valid fill values, or 'none').")
    }

    if type(cell_align) == "array" {
        let align_len = cell_align.len()

        if align_len == 0 {
            // no alignment values specified
            // => inherit from outside
            cell_align = auto
        } else if cell.x == auto {
            // for some reason the cell x wasn't yet
            // determined => just take the last
            // alignment value
            cell_align = cell_align.last()
        } else {
            // use mod to make the align value pattern
            // repeat if there are more columns than
            // align values.
            cell_align = cell_align.at(calc-mod(cell.x, align_len))
        }
    }

    if cell_align != auto and type(cell_align) not in ("alignment", "2d alignment") {
        panic("Tablex error: Invalid alignment specified (must be either a function (column, row) -> alignment, an alignment value - such as 'left' or 'center + top' -, an array of alignment values (one for each column), or 'auto').")
    }

    let aligned_cell_content = if cell_align == auto {
        [#content]
    } else {
        align(cell_align)[#content]
    }

    box(
        width: width, height: height,
        inset: inset, fill: cell_fill,
        // avoid #set problems
        baseline: 0pt,
        outset: 0pt, radius: 0pt, stroke: none,
        aligned_cell_content)
}

// Sums the sizes of fixed-size tracks (cols/rows). Anything else
// (auto, 1fr, ...) is ignored.
#let sum-fixed-size-tracks(tracks) = {
    tracks.fold(0pt, (acc, el) => {
        if type(el) == "length" {
            acc + el
        } else {
            acc
        }
    })
}

// Calculate the size of fraction tracks (cols/rows) (1fr, 2fr, ...),
// based on the remaining sizes (after fixed-size and auto columns)
#let determine-frac-tracks(tracks, remaining: 0pt, gutter: none) = {
    let frac-tracks = enumerate(tracks).filter(t => type(t.at(1)) == "fraction")

    let amount-frac = frac-tracks.fold(0, (acc, el) => acc + (el.at(1) / 1fr))

    if type(gutter) == "fraction" {
        amount-frac += (gutter / 1fr) * (tracks.len() - 1)
    }

    let frac-width = if amount-frac > 0 {
        remaining / amount-frac
    } else {
        0pt
    }

    if type(gutter) == "fraction" {
        gutter = frac-width * (gutter / 1fr)
    }

    for i_size in frac-tracks {
        let i = i_size.at(0)
        let size = i_size.at(1)

        tracks.at(i) = frac-width * (size / 1fr)
    }

    (tracks: tracks, gutter: gutter)
}

// Gets the last (rightmost) auto column a cell is inserted in, for
// due expansion
#let get-colspan-last-auto-col(cell, columns: none) = {
    let cell_cols = range(cell.x, cell.x + cell.colspan)
    let last_auto_col = none

    for i_col in enumerate(columns).filter(i_col => i_col.at(0) in cell_cols) {
        let i = i_col.at(0)
        let col = i_col.at(1)

        if col == auto {
            last_auto_col = max-if-not-none(last_auto_col, i)
        }
    }

    last_auto_col
}

// Gets the last (bottom-most) auto row a cell is inserted in, for
// due expansion
#let get-rowspan-last-auto-row(cell, rows: none) = {
    let cell_rows = range(cell.y, cell.y + cell.rowspan)
    let last_auto_row = none

    for i_row in enumerate(rows).filter(i_row => i_row.at(0) in cell_rows) {
        let i = i_row.at(0)
        let row = i_row.at(1)

        if row == auto {
            last_auto_row = max-if-not-none(last_auto_row, i)
        }
    }

    last_auto_row
}

// Given a cell that may span one or more columns, sums the
// sizes of the columns it spans, when those columns have fixed sizes.
// Useful to subtract from the total width to find out how much more
// should an auto column extend to have that cell fit in the table.
#let get-colspan-fixed-size-covered(cell, columns: none) = {
    let cell_cols = range(cell.x, cell.x + cell.colspan)
    let size = 0pt

    for i_col in enumerate(columns).filter(i_col => i_col.at(0) in cell_cols) {
        let i = i_col.at(0)
        let col = i_col.at(1)

        if type(col) == "length" {
            size += col
        }
    }
    size
}

// Given a cell that may span one or more rows, sums the
// sizes of the rows it spans, when those rows have fixed sizes.
// Useful to subtract from the total height to find out how much more
// should an auto row extend to have that cell fit in the table.
#let get-rowspan-fixed-size-covered(cell, rows: none) = {
    let cell_rows = range(cell.y, cell.y + cell.rowspan)
    let size = 0pt

    for i_row in enumerate(rows).filter(i_row => i_row.at(0) in cell_rows) {
        let i = i_row.at(0)
        let row = i_row.at(1)

        if type(row) == "length" {
            size += row
        }
    }
    size
}

// calculate the size of auto columns (based on the max width of their cells)
#let determine-auto-columns(grid: (), styles: none, columns: none, inset: none) = {
    assert(styles != none, message: "Cannot measure auto columns without styles")
    let total_auto_size = 0pt
    let auto_sizes = ()
    let new_columns = columns

    for i_col in enumerate(columns) {
        let i = i_col.at(0)
        let col = i_col.at(1)

        if col == auto {
            // max cell width
            let col_size = grid-get-column(grid, i)
                .fold(0pt, (max, cell) => {
                    if cell == none {
                        panic("Not enough cells specified for the given amount of rows and columns.")
                    }

                    let pcell = get-parent-cell(cell, grid: grid)  // in case this is a colspan
                    let last_auto_col = get-colspan-last-auto-col(pcell, columns: columns)

                    // only expand the last auto column of a colspan,
                    // and only the amount necessary that isn't already
                    // covered by fixed size columns.
                    if last_auto_col == i {
                        // take extra inset as extra width or height on 'auto'
                        let cell_inset = default-if-auto(pcell.inset, inset)

                        let cell_inset = convert-length-to-pt(cell_inset, styles: styles)

                        let width = measure(pcell.content, styles).width + 2*cell_inset

                        // here, we are excluding from the width of this cell
                        // at this column all width that was already covered by
                        // previous columns, so we need to specify 'new_columns'
                        // instead of 'columns' as the previous auto columns
                        // also have a fixed size now (we know their width).
                        let fixed_size = get-colspan-fixed-size-covered(pcell, columns: new_columns)

                        calc.max(max, width - fixed_size, 0pt)
                    } else {
                        max
                    }
                })

            total_auto_size += col_size
            auto_sizes.push((i, col_size))
            new_columns.at(i) = col_size
        }
    }

    (total: total_auto_size, sizes: auto_sizes, columns: new_columns)
}

#let fit-auto-columns(available: 0pt, auto_cols: none, columns: none) = {
    let remaining = available
    let auto_cols_remaining = auto_cols.len()

    if auto_cols_remaining <= 0 {
        return columns
    }

    let fair_share = remaining / auto_cols_remaining

    for i_col in auto_cols {
        let i = i_col.at(0)
        let col = i_col.at(1)

        if auto_cols_remaining <= 0 {
            return columns  // no more to share
        }

        // subtract AFTER the check!!! (Avoid off-by-one error)
        auto_cols_remaining -= 1

        if col < fair_share {  // ok, keep your size, it's less than the limit
            remaining -= col

            if auto_cols_remaining > 0 {
                fair_share = remaining / auto_cols_remaining
            }
        } else {  // you surpassed the limit!!!
            remaining -= fair_share
            columns.at(i) = fair_share
        }
    }

    columns
}

#let determine-column-sizes(grid: (), page_width: 0pt, styles: none, columns: none, inset: none, col-gutter: none) = {
    let columns = columns.map(c => {
        if type(c) in ("length", "relative length", "ratio") {
            convert-length-to-pt(c, styles: styles, page_size: page_width)
        } else if c == none {
            0pt
        } else {
            c
        }
    })

    // what is the fixed size of the gutter?
    // (calculate it later if it's fractional)
    let fixed-size-gutter = if type(col-gutter) == "length" {
        col-gutter
    } else {
        0pt
    }

    let total_fixed_size = sum-fixed-size-tracks(columns) + fixed-size-gutter * (columns.len() - 1)

    let available_size = page_width - total_fixed_size

    // page_width == 0pt => page width is 'auto'
    // so we don't have to restrict our table's size
    if available_size >= 0pt or page_width == 0pt {
        let auto_cols_result = determine-auto-columns(grid: grid, styles: styles, columns: columns, inset: inset)
        let total_auto_size = auto_cols_result.total
        let auto_sizes = auto_cols_result.sizes
        columns = auto_cols_result.columns

        let remaining_size = available_size - total_auto_size
        if remaining_size >= 0pt {
            let frac_res = determine-frac-tracks(
                columns,
                remaining: remaining_size,
                gutter: col-gutter
            )

            columns = frac_res.tracks
            fixed-size-gutter = frac_res.gutter
        } else {
            // don't shrink on width 'auto'
            if page_width != 0pt {
                columns = fit-auto-columns(
                    available: available_size,
                    auto_cols: auto_sizes,
                    columns: columns
                )
            }

            columns = columns.map(c => {
                if type(c) == "fraction" {
                    0pt  // no space left to be divided
                } else {
                    c
                }
            })
        }
    } else {
        columns = columns.map(c => {
            if c == auto or type(c) == "fraction" {
                0pt  // no space remaining!
            } else {
                c
            }
        })
    }

    (
        columns: columns,
        gutter: if col-gutter == none {
            none
        } else {
            fixed-size-gutter
        }
    )
}

// calculate the size of auto rows (based on the max height of their cells)
#let determine-auto-rows(grid: (), styles: none, columns: none, rows: none, align: auto, inset: none) = {
    assert(styles != none, message: "Cannot measure auto rows without styles")
    let total_auto_size = 0pt
    let auto_sizes = ()
    let new_rows = rows

    for i_row in enumerate(rows) {
        let i = i_row.at(0)
        let row = i_row.at(1)

        if row == auto {
            // max cell height
            let row_size = grid-get-row(grid, i)
                .fold(0pt, (max, cell) => {
                    if cell == none {
                        panic("Not enough cells specified for the given amount of rows and columns.")
                    }

                    let pcell = get-parent-cell(cell, grid: grid)  // in case this is a rowspan
                    let last_auto_row = get-rowspan-last-auto-row(pcell, rows: rows)

                    // only expand the last auto row of a rowspan,
                    // and only the amount necessary that isn't already
                    // covered by fixed size rows.
                    if last_auto_row == i {
                        let width = get-colspan-fixed-size-covered(pcell, columns: columns)

                        // take extra inset as extra width or height on 'auto'
                        let cell_inset = default-if-auto(pcell.inset, inset)

                        let cell_inset = convert-length-to-pt(cell_inset, styles: styles)

                        let cell-box = make-cell-box(
                            pcell,
                            width: width, height: auto,
                            inset: cell_inset, align_default: align
                        )

                        // measure the cell's actual height,
                        // with its calculated width
                        // and with other constraints
                        let height = measure(cell-box, styles).height// + 2*cell_inset (box already considers inset)

                        // here, we are excluding from the height of this cell
                        // at this row all height that was already covered by
                        // other rows, so we need to specify 'new_rows' instead
                        // of 'rows' as the previous auto rows also have a fixed
                        // size now (we know their height).
                        let fixed_size = get-rowspan-fixed-size-covered(pcell, rows: new_rows)

                        calc.max(max, height - fixed_size, 0pt)
                    } else {
                        max
                    }
                })

            total_auto_size += row_size
            auto_sizes.push((i, row_size))
            new_rows.at(i) = row_size
        }
    }

    (total: total_auto_size, sizes: auto_sizes, rows: new_rows)
}

#let determine-row-sizes(grid: (), page_height: 0pt, styles: none, columns: none, rows: none, align: auto, inset: none, row-gutter: none) = {
    let rows = rows.map(r => {
        if type(r) in ("length", "relative length", "ratio") {
            convert-length-to-pt(r, styles: styles, page_size: page_height)
        } else {
            r
        }
    })

    let auto_rows_res = determine-auto-rows(
        grid: grid, columns: columns, rows: rows, styles: styles, align: align, inset: inset
    )

    let auto_size = auto_rows_res.total
    rows = auto_rows_res.rows

    // what is the fixed size of the gutter?
    // (calculate it later if it's fractional)
    let fixed-size-gutter = if type(row-gutter) == "length" {
        row-gutter
    } else {
        0pt
    }

    let remaining = page_height - sum-fixed-size-tracks(rows) - auto_size - fixed-size-gutter * (rows.len() - 1)

    if remaining >= 0pt {  // split fractions in one page
        let frac_res = determine-frac-tracks(rows, remaining: remaining, gutter: row-gutter)
        (
            rows: frac_res.tracks,
            gutter: frac_res.gutter
        )
    } else {
        (
            rows: rows.map(r => {
                if type(r) == "fraction" {  // no space remaining in this page or box
                    0pt
                } else {
                    r
                }
            }),
            gutter: if row-gutter == none {
                none
            } else {
                fixed-size-gutter
            }
        )
    }
}

// Determine the size of 'auto' and 'fr' columns and rows
#let determine-auto-column-row-sizes(
    grid: (),
    page_width: 0pt, page_height: 0pt,
    styles: none,
    columns: none, rows: none,
    inset: none, gutter: none,
    align: auto,
) = {
    let inset = convert-length-to-pt(inset, styles: styles)

    let columns_res = determine-column-sizes(
        grid: grid,
        page_width: page_width, styles: styles, columns: columns,
        inset: inset,
        col-gutter: gutter.col
    )
    columns = columns_res.columns
    gutter.col = columns_res.gutter

    let rows_res = determine-row-sizes(
        grid: grid,
        page_height: page_height, styles: styles,
        columns: columns,  // so we consider available width
        rows: rows,
        inset: inset,
        align: align,
        row-gutter: gutter.row
    )
    rows = rows_res.rows
    gutter.row = rows_res.gutter

    (
        columns: columns,
        rows: rows,
        gutter: gutter
    )
}
