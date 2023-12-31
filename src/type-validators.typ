// #02
// Type validators, and also rowspanx and colspanx.

// -- tablex imports --
#import "common.typ": *
#import "types.typ": *
// -- end imports --

// Is this a valid dict created by this library?
#let is-tablex-dict(x) = (
    type(x) == _dict-type
        and "tablex-dict-type" in x
)

#let is-tablex-dict-type(x, ..dict-types) = (
    is-tablex-dict(x)
        and x.tablex-dict-type in dict-types.pos()
)

#let is-tablex-cell(x) = is-tablex-dict-type(x, "cell")
#let is-tablex-hline(x) = is-tablex-dict-type(x, "hline")
#let is-tablex-vline(x) = is-tablex-dict-type(x, "vline")
#let is-some-tablex-line(x) = is-tablex-dict-type(x, "hline", "vline")
#let is-tablex-occupied(x) = is-tablex-dict-type(x, "occupied")

#let table-item-convert(item, keep-empty: true) = {
    if type(item) == _function-type {  // dynamic cell content
        cellx(item)
    } else if keep-empty and item == () {
        item
    } else if type(item) != _dict-type or "tablex-dict-type" not in item {
        cellx[#item]
    } else {
        item
    }
}

#let rowspanx(length, content, ..cell-options) = {
    if is-tablex-cell(content) {
        (..content, rowspan: length, ..cell-options.named())
    } else {
        cellx(
            content,
            rowspan: length,
            ..cell-options.named())
    }
}

#let colspanx(length, content, ..cell-options) = {
    if is-tablex-cell(content) {
        (..content, colspan: length, ..cell-options.named())
    } else {
        cellx(
            content,
            colspan: length,
            ..cell-options.named())
    }
}

// Get expected amount of cell positions
// in the table (considering colspan and rowspan)
#let get-expected-grid-len(items, col-len: 0) = {
    let len = 0

    // maximum explicit 'y' specified
    let max-explicit-y = items
        .filter(c => c.y != auto)
        .fold(0, (acc, cell) => {
            if (is-tablex-cell(cell)
                    and type(cell.y) in (_int-type, _float-type)
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
        } else if type(item) == _content-type {
            len += 1
        }
    }

    let rows(len) = calc.ceil(len / col-len)

    while rows(len) < max-explicit-y {
        len += col-len
    }

    len
}

// Check if this length is infinite.
#let is-infinite-len(len) = {
    type(len) in (_ratio-type, _fraction-type, _rel-len-type, _length-type) and "inf" in repr(len)
}

// Check if the given length has type '_length-type' and no 'em' component.
#let is-purely-pt-len(len) = {
    type(len) == _length-type and ((typst-fields-supported and len.em == 0) or (not typst-fields-supported and "em" not in repr(len)))
}

// Check if this is a valid color (color, gradient or pattern).
#let is-color(val) = {
    type(val) == _color-type or str(type(val)) in ("gradient", "pattern")
}

#let validate-cols-rows(columns, rows, items: ()) = {
    if type(columns) == _int-type {
        assert(columns >= 0, message: "Error: Cannot have a negative amount of columns.")

        columns = (auto,) * columns
    }

    if type(rows) == _int-type {
        assert(rows >= 0, message: "Error: Cannot have a negative amount of rows.")
        rows = (auto,) * rows
    }

    if type(columns) != _array-type {
        columns = (columns,)
    }

    if type(rows) != _array-type {
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

    let col-row-is-valid(col-row) = (
        (not is-infinite-len(col-row)) and (col-row == auto or type(col-row) in (
            _fraction-type, _length-type, _rel-len-type, _ratio-type
            ))
    )

    if not columns.all(col-row-is-valid) {
        panic("Invalid column sizes (must all be 'auto' or a valid, finite length specifier).")
    }

    if not rows.all(col-row-is-valid) {
        panic("Invalid row sizes (must all be 'auto' or a valid, finite length specifier).")
    }

    let col-len = columns.len()

    let grid-len = get-expected-grid-len(items, col-len: col-len)

    let expected-rows = calc.ceil(grid-len / col-len)

    // more cells than expected => add rows
    if rows.len() < expected-rows {
        let missing-rows = expected-rows - rows.len()

        rows += (rows.last(),) * missing-rows
    }

    (columns: columns, rows: rows, items: ())
}
