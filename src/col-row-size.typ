// #05
// Functions related to the calculation of the sizes of columns and rows.

// -- tablex imports --
#import "common.typ": *
#import "types.typ": *
#import "type-validators.typ": *
#import "utilities.typ": *
#import "grid.typ": *
// -- end imports --

// Makes a cell's box, using the given options
// cell - The cell data (including content)
// width, height - The cell's dimensions
// inset - The table's inset
// align-default - The default alignment if the cell doesn't specify one
// fill-default - The default fill color / etc if the cell doesn't specify one
#let make-cell-box(
        cell,
        width: 0pt, height: 0pt, inset: 5pt,
        align-default: left,
        fill-default: none) = {

    let align-default = if type(align-default) == _function_type {
        align-default(cell.x, cell.y)  // column, row
    } else {
        align-default
    }

    let fill-default = if type(fill-default) == _function_type {
        fill-default(cell.x, cell.y)  // row, column
    } else {
        fill-default
    }

    let content = cell.content

    let inset = default-if-auto(cell.inset, inset)

    // use default align (specified in
    // table 'align:')
    // when the cell align is 'auto'
    let cell-align = default-if-auto(cell.align, align-default)

    // same here for fill
    let cell-fill = default-if-auto(cell.fill, fill-default)

    if type(cell-fill) == _array_type {
        let fill-len = cell-fill.len()

        if fill-len == 0 {
            // no fill values specified
            // => no fill
            cell-fill = none
        } else if cell.x == auto {
            // for some reason the cell x wasn't yet
            // determined => just take the last
            // fill value
            cell-fill = cell-fill.last()
        } else {
            // use mod to make the fill value pattern
            // repeat if there are more columns than
            // fill values.
            cell-fill = cell-fill.at(calc-mod(cell.x, fill-len))
        }
    }

    if cell-fill != none and not is-color(cell-fill) {
        panic("Tablex error: Invalid fill specified (must be either a function (column, row) -> fill, a color, an array of valid fill values, or 'none').")
    }

    if type(cell-align) == _array_type {
        let align-len = cell-align.len()

        if align-len == 0 {
            // no alignment values specified
            // => inherit from outside
            cell-align = auto
        } else if cell.x == auto {
            // for some reason the cell x wasn't yet
            // determined => just take the last
            // alignment value
            cell-align = cell-align.last()
        } else {
            // use mod to make the align value pattern
            // repeat if there are more columns than
            // align values.
            cell-align = cell-align.at(calc-mod(cell.x, align-len))
        }
    }

    if cell-align != auto and type(cell-align) not in (_align_type, _2d_align_type) {
        panic("Tablex error: Invalid alignment specified (must be either a function (column, row) -> alignment, an alignment value - such as 'left' or 'center + top' -, an array of alignment values (one for each column), or 'auto').")
    }

    let aligned-cell-content = if cell-align == auto {
        [#content]
    } else {
        align(cell-align)[#content]
    }

    if is-infinite-len(inset) {
        panic("Tablex error: inset must not be infinite")
    }

    box(
        width: width, height: height,
        inset: inset, fill: cell-fill,
        // avoid #set problems
        baseline: 0pt,
        outset: 0pt, radius: 0pt, stroke: none,
        aligned-cell-content)
}

// Sums the sizes of fixed-size tracks (cols/rows). Anything else
// (auto, 1fr, ...) is ignored.
#let sum-fixed-size-tracks(tracks) = {
    tracks.fold(0pt, (acc, el) => {
        if type(el) == _length_type {
            acc + el
        } else {
            acc
        }
    })
}

// Calculate the size of fraction tracks (cols/rows) (1fr, 2fr, ...),
// based on the remaining sizes (after fixed-size and auto columns)
#let determine-frac-tracks(tracks, remaining: 0pt, gutter: none) = {
    let frac-tracks = enumerate(tracks).filter(t => type(t.at(1)) == _fraction_type)

    let amount-frac = frac-tracks.fold(0, (acc, el) => acc + (el.at(1) / 1fr))

    if type(gutter) == _fraction_type {
        amount-frac += (gutter / 1fr) * (tracks.len() - 1)
    }

    let frac-width = if amount-frac > 0 and not is-infinite-len(remaining) {
        remaining / amount-frac
    } else {
        0pt
    }

    if type(gutter) == _fraction_type {
        gutter = frac-width * (gutter / 1fr)
    }

    for i-size in frac-tracks {
        let i = i-size.at(0)
        let size = i-size.at(1)

        tracks.at(i) = frac-width * (size / 1fr)
    }

    (tracks: tracks, gutter: gutter)
}

// Gets the last (rightmost) auto column a cell is inserted in, for
// due expansion
#let get-colspan-last-auto-col(cell, columns: none) = {
    let cell-cols = range(cell.x, cell.x + cell.colspan)
    let last-auto-col = none

    for i-col in enumerate(columns).filter(i-col => i-col.at(0) in cell-cols) {
        let i = i-col.at(0)
        let col = i-col.at(1)

        if col == auto {
            last-auto-col = max-if-not-none(last-auto-col, i)
        }
    }

    last-auto-col
}

// Gets the last (bottom-most) auto row a cell is inserted in, for
// due expansion
#let get-rowspan-last-auto-row(cell, rows: none) = {
    let cell-rows = range(cell.y, cell.y + cell.rowspan)
    let last-auto-row = none

    for i-row in enumerate(rows).filter(i-row => i-row.at(0) in cell-rows) {
        let i = i-row.at(0)
        let row = i-row.at(1)

        if row == auto {
            last-auto-row = max-if-not-none(last-auto-row, i)
        }
    }

    last-auto-row
}

// Given a cell that may span one or more columns, sums the
// sizes of the columns it spans, when those columns have fixed sizes.
// Useful to subtract from the total width to find out how much more
// should an auto column extend to have that cell fit in the table.
#let get-colspan-fixed-size-covered(cell, columns: none) = {
    let cell-cols = range(cell.x, cell.x + cell.colspan)
    let size = 0pt

    for i-col in enumerate(columns).filter(i-col => i-col.at(0) in cell-cols) {
        let i = i-col.at(0)
        let col = i-col.at(1)

        if type(col) == _length_type {
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
    let cell-rows = range(cell.y, cell.y + cell.rowspan)
    let size = 0pt

    for i-row in enumerate(rows).filter(i-row => i-row.at(0) in cell-rows) {
        let i = i-row.at(0)
        let row = i-row.at(1)

        if type(row) == _length_type {
            size += row
        }
    }
    size
}

// calculate the size of auto columns (based on the max width of their cells)
#let determine-auto-columns(grid: (), styles: none, columns: none, inset: none, align: auto) = {
    assert(styles != none, message: "Cannot measure auto columns without styles")
    let total-auto-size = 0pt
    let auto-sizes = ()
    let new-columns = columns

    for i-col in enumerate(columns) {
        let i = i-col.at(0)
        let col = i-col.at(1)

        if col == auto {
            // max cell width
            let col-size = grid-get-column(grid, i)
                .fold(0pt, (max, cell) => {
                    if cell == none {
                        panic("Not enough cells specified for the given amount of rows and columns.")
                    }

                    let pcell = get-parent-cell(cell, grid: grid)  // in case this is a colspan
                    let last-auto-col = get-colspan-last-auto-col(pcell, columns: columns)

                    // only expand the last auto column of a colspan,
                    // and only the amount necessary that isn't already
                    // covered by fixed size columns.
                    if last-auto-col == i {
                        // take extra inset as extra width or height on 'auto'
                        let cell-inset = default-if-auto(pcell.inset, inset)

                        // simulate wrapping this cell in the final box,
                        // but with unlimited width and height available
                        // so we can measure its width.
                        let cell-box = make-cell-box(
                            pcell,
                            width: auto, height: auto,
                            inset: cell-inset, align-default: auto
                        )

                        let width = measure(cell-box, styles).width// + 2*cell-inset // the box already considers inset

                        // here, we are excluding from the width of this cell
                        // at this column all width that was already covered by
                        // previous columns, so we need to specify 'new-columns'
                        // instead of 'columns' as the previous auto columns
                        // also have a fixed size now (we know their width).
                        let fixed-size = get-colspan-fixed-size-covered(pcell, columns: new-columns)

                        calc.max(max, width - fixed-size, 0pt)
                    } else {
                        max
                    }
                })

            total-auto-size += col-size
            auto-sizes.push((i, col-size))
            new-columns.at(i) = col-size
        }
    }

    (total: total-auto-size, sizes: auto-sizes, columns: new-columns)
}

#let fit-auto-columns(available: 0pt, auto-cols: none, columns: none) = {
    if is-infinite-len(available) {
        // infinite space available => don't modify columns
        return columns
    }

    let remaining = available
    let auto-cols-remaining = auto-cols.len()

    if auto-cols-remaining <= 0 {
        return columns
    }

    let fair-share = remaining / auto-cols-remaining

    for i-col in auto-cols {
        let i = i-col.at(0)
        let col = i-col.at(1)

        if auto-cols-remaining <= 0 {
            return columns  // no more to share
        }

        // subtract AFTER the check!!! (Avoid off-by-one error)
        auto-cols-remaining -= 1

        if col < fair-share {  // ok, keep your size, it's less than the limit
            remaining -= col

            if auto-cols-remaining > 0 {
                fair-share = remaining / auto-cols-remaining
            }
        } else {  // you surpassed the limit!!!
            remaining -= fair-share
            columns.at(i) = fair-share
        }
    }

    columns
}

#let determine-column-sizes(grid: (), page-width: 0pt, styles: none, columns: none, inset: none, align: auto, col-gutter: none) = {
    let columns = columns.map(c => {
        if type(c) in (_length_type, _rel_len_type, _ratio_type) {
            convert-length-to-pt(c, styles: styles, page-size: page-width)
        } else if c == none {
            0pt
        } else {
            c
        }
    })

    // what is the fixed size of the gutter?
    // (calculate it later if it's fractional)
    let fixed-size-gutter = if type(col-gutter) == _length_type {
        col-gutter
    } else {
        0pt
    }

    let total-fixed-size = sum-fixed-size-tracks(columns) + fixed-size-gutter * (columns.len() - 1)

    let available-size = page-width - total-fixed-size

    // page-width == 0pt => page width is 'auto'
    // so we don't have to restrict our table's size
    if available-size >= 0pt or page-width == 0pt {
        let auto-cols-result = determine-auto-columns(grid: grid, styles: styles, columns: columns, inset: inset, align: align)
        let total-auto-size = auto-cols-result.total
        let auto-sizes = auto-cols-result.sizes
        columns = auto-cols-result.columns

        let remaining-size = available-size - total-auto-size
        if remaining-size >= 0pt {
            let frac-res = determine-frac-tracks(
                columns,
                remaining: remaining-size,
                gutter: col-gutter
            )

            columns = frac-res.tracks
            fixed-size-gutter = frac-res.gutter
        } else {
            // don't shrink on width 'auto'
            if page-width != 0pt {
                columns = fit-auto-columns(
                    available: available-size,
                    auto-cols: auto-sizes,
                    columns: columns
                )
            }

            columns = columns.map(c => {
                if type(c) == _fraction_type {
                    0pt  // no space left to be divided
                } else {
                    c
                }
            })
        }
    } else {
        columns = columns.map(c => {
            if c == auto or type(c) == _fraction_type {
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
    let total-auto-size = 0pt
    let auto-sizes = ()
    let new-rows = rows

    for i-row in enumerate(rows) {
        let i = i-row.at(0)
        let row = i-row.at(1)

        if row == auto {
            // max cell height
            let row-size = grid-get-row(grid, i)
                .fold(0pt, (max, cell) => {
                    if cell == none {
                        panic("Not enough cells specified for the given amount of rows and columns.")
                    }

                    let pcell = get-parent-cell(cell, grid: grid)  // in case this is a rowspan
                    let last-auto-row = get-rowspan-last-auto-row(pcell, rows: rows)

                    // only expand the last auto row of a rowspan,
                    // and only the amount necessary that isn't already
                    // covered by fixed size rows.
                    if last-auto-row == i {
                        let width = get-colspan-fixed-size-covered(pcell, columns: columns)

                        // take extra inset as extra width or height on 'auto'
                        let cell-inset = default-if-auto(pcell.inset, inset)

                        let cell-box = make-cell-box(
                            pcell,
                            width: width, height: auto,
                            inset: cell-inset, align-default: align
                        )

                        // measure the cell's actual height,
                        // with its calculated width
                        // and with other constraints
                        let height = measure(cell-box, styles).height// + 2*cell-inset (box already considers inset)

                        // here, we are excluding from the height of this cell
                        // at this row all height that was already covered by
                        // other rows, so we need to specify 'new-rows' instead
                        // of 'rows' as the previous auto rows also have a fixed
                        // size now (we know their height).
                        let fixed-size = get-rowspan-fixed-size-covered(pcell, rows: new-rows)

                        calc.max(max, height - fixed-size, 0pt)
                    } else {
                        max
                    }
                })

            total-auto-size += row-size
            auto-sizes.push((i, row-size))
            new-rows.at(i) = row-size
        }
    }

    (total: total-auto-size, sizes: auto-sizes, rows: new-rows)
}

#let determine-row-sizes(grid: (), page-height: 0pt, styles: none, columns: none, rows: none, align: auto, inset: none, row-gutter: none) = {
    let rows = rows.map(r => {
        if type(r) in (_length_type, _rel_len_type, _ratio_type) {
            convert-length-to-pt(r, styles: styles, page-size: page-height)
        } else {
            r
        }
    })

    let auto-rows-res = determine-auto-rows(
        grid: grid, columns: columns, rows: rows, styles: styles, align: align, inset: inset
    )

    let auto-size = auto-rows-res.total
    rows = auto-rows-res.rows

    // what is the fixed size of the gutter?
    // (calculate it later if it's fractional)
    let fixed-size-gutter = if type(row-gutter) == _length_type {
        row-gutter
    } else {
        0pt
    }

    let remaining = page-height - sum-fixed-size-tracks(rows) - auto-size - fixed-size-gutter * (rows.len() - 1)

    if remaining >= 0pt {  // split fractions in one page
        let frac-res = determine-frac-tracks(rows, remaining: remaining, gutter: row-gutter)
        (
            rows: frac-res.tracks,
            gutter: frac-res.gutter
        )
    } else {
        (
            rows: rows.map(r => {
                if type(r) == _fraction_type {  // no space remaining in this page or box
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
    page-width: 0pt, page-height: 0pt,
    styles: none,
    columns: none, rows: none,
    inset: none, gutter: none,
    align: auto,
) = {
    let columns-res = determine-column-sizes(
        grid: grid,
        page-width: page-width, styles: styles, columns: columns,
        inset: inset,
        align: align,
        col-gutter: gutter.col
    )
    columns = columns-res.columns
    gutter.col = columns-res.gutter

    let rows-res = determine-row-sizes(
        grid: grid,
        page-height: page-height, styles: styles,
        columns: columns,  // so we consider available width
        rows: rows,
        inset: inset,
        align: align,
        row-gutter: gutter.row
    )
    rows = rows-res.rows
    gutter.row = rows-res.gutter

    (
        columns: columns,
        rows: rows,
        gutter: gutter
    )
}
