// #02
// Type validators, and also rowspanx and colspanx.

// -- tablex imports --
#import "common.typ": *
#import "types.typ": *
// -- end imports --

// Is this a valid dict created by this library?
#let is-tablex-dict(x) = (
    type(x) == "dictionary"
        and "tablex-dict-type" in x
)

#let is-tablex-dict-type(x, ..dict_types) = (
    is-tablex-dict(x)
        and x.tablex-dict-type in dict_types.pos()
)

#let is-tablex-cell(x) = is-tablex-dict-type(x, "cell")
#let is-tablex-hline(x) = is-tablex-dict-type(x, "hline")
#let is-tablex-vline(x) = is-tablex-dict-type(x, "vline")
#let is-some-tablex-line(x) = is-tablex-dict-type(x, "hline", "vline")
#let is-tablex-occupied(x) = is-tablex-dict-type(x, "occupied")

#let table-item-convert(item, keep_empty: true) = {
    if type(item) == "function" {  // dynamic cell content
        cellx(item)
    } else if keep_empty and item == () {
        item
    } else if type(item) != "dictionary" or "tablex-dict-type" not in item {
        cellx[#item]
    } else {
        item
    }
}

#let rowspanx(length, content, ..cell_options) = {
    if is-tablex-cell(content) {
        (..content, rowspan: length, ..cell_options.named())
    } else {
        cellx(
            content,
            rowspan: length,
            ..cell_options.named())
    }
}

#let colspanx(length, content, ..cell_options) = {
    if is-tablex-cell(content) {
        (..content, colspan: length, ..cell_options.named())
    } else {
        cellx(
            content,
            colspan: length,
            ..cell_options.named())
    }
}

// Get expected amount of cell positions
// in the table (considering colspan and rowspan)
#let get-expected-grid-len(items, col_len: 0) = {
    let len = 0

    // maximum explicit 'y' specified
    let max_explicit_y = items
        .filter(c => c.y != auto)
        .fold(0, (acc, cell) => {
            if (is-tablex-cell(cell)
                    and type(cell.y) in ("integer", "float")
                    and cell.y > acc) {
                cell.y
            } else {
                acc
            }
        })

    for item in items {
        if is-tablex-cell(item) and item.x == auto and item.y == auto {
            // cell occupies (colspan * rowspan) spaces
            len += item.colspan * item.rowspan
        } else if type(item) == "content" {
            len += 1
        }
    }

    let rows(len) = calc.ceil(len / col_len)

    while rows(len) < max_explicit_y {
        len += col_len
    }

    len
}

#let validate-cols-rows(columns, rows, items: ()) = {
    if type(columns) == "integer" {
        assert(columns >= 0, message: "Error: Cannot have a negative amount of columns.")

        columns = (auto,) * columns
    }

    if type(rows) == "integer" {
        assert(rows >= 0, message: "Error: Cannot have a negative amount of rows.")
        rows = (auto,) * rows
    }

    if type(columns) != "array" {
        columns = (columns,)
    }

    if type(rows) != "array" {
        rows = (rows,)
    }

    // default empty column to a single auto column
    if columns.len() == 0 {
        columns = (auto,)
    }

    // default empty row to a single auto row
    if rows.len() == 0 {
        rows = (auto,)
    }

    let col_row_is_valid(col_row) = (
        col_row == auto or type(col_row) in (
            "fraction", "length", "relative length", "ratio"
            )
    )

    if not columns.all(col_row_is_valid) {
        panic("Invalid column sizes (must all be 'auto' or a valid length specifier).")
    }

    if not rows.all(col_row_is_valid) {
        panic("Invalid row sizes (must all be 'auto' or a valid length specifier).")
    }

    let col_len = columns.len()

    let grid_len = get-expected-grid-len(items, col_len: col_len)

    let expected_rows = calc.ceil(grid_len / col_len)

    // more cells than expected => add rows
    if rows.len() < expected_rows {
        let missing_rows = expected_rows - rows.len()

        rows += (rows.last(),) * missing_rows
    }

    (columns: columns, rows: rows, items: ())
}
