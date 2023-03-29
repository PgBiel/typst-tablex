#let hline(start: 0, end: auto, y: auto) = (
    tabular_dict_type: "hline",
    start: start,
    end: end,
    y: y
)

#let vline(start: 0, end: auto, x: auto) = (
    tabular_dict_type: "vline",
    start: start,
    end: end,
    x: x
)

#let tcell(content, rowspan: 1, colspan: 1) = (
    tabular_dict_type: "cell",
    content: content,
    rowspan: rowspan,
    colspan: colspan,
    x: auto,
    y: auto,
)

#let occupied(x: none, y: none) = (
    tabular_dict_type: "occupied",
    x: x,
    y: y
)

#let rowspan(content, length: 1) = tcell(content, rowspan: length)

#let colspan(content, length: 1) = tcell(content, colspan: length)

// Is this a valid dict created by this library?
#let is_tabular_dict(x) = (
    type(x) == "dictionary"
        and "tabular_dict_type" in x
)

#let is_tabular_dict_type(x, ..dict_types) = (
    is_tabular_dict(x)
        and x.is_tabular_dict_type in dict_types.pos()
)

// type checks
#let is_tabular_cell(x) = is_tabular_dict_type(x, "cell")
#let is_tabular_hline(x) = is_tabular_dict_type(x, "hline")
#let is_tabular_vline(x) = is_tabular_dict_type(x, "vline")
#let is_some_tabular_line(x) = is_tabular_dict_type(x, "hline", "vline")
#let is_tabular_occupied(x) = is_tabular_dict_type(x, "occupied")

#let table_item_convert(item) = {
    if type(item) == "function" {  // dynamic cell content
        tcell(item)
    } else if type(item) != "dictionary" or "tabular_dict_type" not in item {
        tcell[#item]
    } else {
        it
    }
}

// Which positions does a cell occupy
// (Usually just its own, but increases if colspan / rowspan
// is greater than 1)
#let positions_spanned_by(cell, x: 0, y: 0, x_limit: 0, y_limit: 0) = {
    let result = ()
    let rowspan = cell.rowspan
    let colspan = cell.colspan

    if rowspan < 1 {
        panic("Cell rowspan must be 1 or greater (bad cell: ", (x, y), ")")
    } else if colspan < 1 {
        panic("Cell colspan must be 1 or greater (bad cell: ", (x, y), ")")
    }

    let max_x = calc.min(x_limit, x + colspan)
    let max_y = calc.min(y_limit, y + rowspan)

    for x in range(x, max_x) {
        for y in range(y, max_y) {
            result.push((x, y))
        }
    }

    result
}

// initialize an array with a certain element or init function, repeated
#let init_array(amount, element: none, init_function: none) = {
    let nones = ()

    if init_function == none {
        init_function = () => element
    }

    range(amount).map(i => init_function())
}

// Default 'x' to a certain value if it is equal to the forbidden value
// ('none' by default)
#let default_if_none(x, default, forbidden: none) = {
    if x == forbidden {
        default
    } else {
        x
    }
}

// The max between a, b, or the other one if either is 'none'.
#let max_if_not_none(a, b) = if a == none {
    b
} else if b == none {
    a
} else {
    calc.max(a, b)
}

// Convert a certain (non-relative) length to pt
#let convert_length_to_pt(len, styles) = {
    let line = line(length: len)
    measure(line, styles).width
}

// --- end: utility functions ---


// --- grid functions ---

// Gets the cell at the given grid x, y position
// E.g. grid_at(grid, 5, 2)  => 5th column, 2nd row
#let grid_at(grid, ..pair) = {
    let pair_pos = pair.pos()
    let x = pair_pos.at(0)
    let y = pair_pos.at(1)

    grid.at(y).at(x)
}

// Return the next position available on the grid
#let next_available_position(grid, x: 0, y: 0, x_limit: 0, y_limit: 0) = {
    let cell = (x, y)

    while grid_at(grid, ..cell) != none {
        x += 1

        if x >= x_limit {
            x = 0
            y += 1
        }

        if y >= y_limit {
            return none
        }

        cell = (x, y)
    }

    cell
}

// Organize cells in a grid from the given items,
// and also get all given lines
#let generate_grid(items, x_limit: 0, y_limit: 0) = {
    // init grid as a matrix
    // y_limit  x   x_limit
    let grid = init_array(y_limit, init_function: init_array.with(x_limit))

    let hlines = ()
    let vlines = ()

    let prev_x = 0
    let prev_y = 0

    let x = 0
    let y = 0

    let row_wrapped = false  // if true, a vline should be added to the end of a row

    for i in range(items.len()) {
        let item = items.at(i)

        if is_some_tabular_line(item) {  // detect lines' x, y
            if is_tabular_hline(item) {
                item.y = default_if_none(y, row_len)

                hlines.push(item)
            } else if is_tabular_vline(item) {
                if row_wrapped {
                    item.x = prev_x + 1  // allow v_line at the last column
                    row_wrapped = false
                } else {
                    item.x = x
                }

                vlines.push(item)
            } else {
                panic("Invalid line received (must be hline or vline).")
            }
            items.at(i) = item  // override item with the new x / y coord set
        }

        if not is_tabular_cell(item) {
            continue
        }

        let cell = item
        if x == none or y == none {
            panic("Attempted to add cells with no space available! Maybe there are too many cells? Failing cell's position:", (prev_x, prev_y))
        }

        let cell_positions = positions_spanned_by(cell, x: x, y: y, x_limit: x_limit, y_limit: y_limit)
        let is_multicell = cell_positions.len() > 1

        for position in cell_positions {
            let px = position.at(0)
            let py = position.at(1)
            let currently_there = grid_at(grid, px, py)

            if currently_there != none {
                panic("The following cells attempted to occupy the same space: one starting at", (x, y), "and one at", (px, py))
            }

            // initial position => assign it to the cell's x/y
            if position == (x, y) {
                cell.x = x
                cell.y = y
                grid.at(y).at(x) = cell
                items.at(i) = cell
            
            // other secondary position (from colspan / rowspan)
            } else {
                grid.at(py).at(px) = occupied(x: x, y: y)  // signal parent cell
            }
        }

        let next_pos = next_available_position(grid, x: x, y: y, x_limit: x_limit, y_limit: y_limit)

        prev_x = x
        prev_y = y

        if next_pos == none {
            x = none
            y = none

            row_wrapped = true  // reached the end of the grid
        } else {
            x = next_pos.at(0)
            y = next_pos.at(1)

            if prev_y != y {
                row_wrapped = true  // we changed rows!
            }
        }
    }

    (
        grid: grid,
        hlines: hlines,
        vlines: vlines
    )
}

// Determine the size of 'auto' columns and rows
#let determine_auto_column_row_sizes(grid, styles: none, columns: none, rows: none) = {
    if auto not in columns and auto not in rows {
        (columns, rows)  // no action necessary if no auto's are present
    } else {
        let new_cols = columns.map(it => if it == auto { none } else { it })
        let partial_cols = init_array(col_len)  // for colspans

        let new_rows = rows.map(it => if it == auto { none } else { it })
        let partial_rows = init_array(row_len)

        for row in grid {
            for cell in row {
                if cell == none {
                    panic("Not enough cells specified for the given amount of rows and columns.")
                }
                if is_occupied(cell) {  // placeholder - ignore
                    continue
                }
                let col_count = cell.x
                let row_count = cell.y

                if cell.colspan > 1 {
                    let previous_width = 0pt  // TODO: sum previous widths and whatnot
                    let last_auto_column = none  // the last 'auto' column within this colspan should be resized to fit the colspan cell's width
                    for affected_column in range(cell.x, cell.x + cell.colspan) {
                        if columns.at(affected_column) == auto {
                            last_auto_column = affected_column
                        }
                    }

                    if last_auto_column != none {  // resize the last auto column to fit this cell
                        let measures = measure(cell.content, styles)
                        let width = measures.width

                        new_cols.at(last_auto_column) = max_if_not_none(width, new_cols.at(last_auto_column))
                    }
                } else if columns.at(col_count) == auto {
                    let measures = measure(cell.content, styles)
                    let width = measures.width
                    new_cols.at(col_count) = max_if_not_none(width, new_cols.at(col_count))
                }

                // TODO: Proceed from here
                if rows.at(row_count) == auto {
                    let measures = measure(cell.content, styles)
                    let height = measures.height
                    if cell.rowspan > 1 {
                        partial_rows.at(row_count) = max_if_not_none(height, partial_rows.at(row_count))
                    } else {
                        new_rows.at(row_count) = max_if_not_none(height, new_rows.at(row_count))
                    }
                }
            }
        }

        let i = 0
        for i in range(new_cols.len()) {
            if new_cols.at(i) == none {
                let partial = partial_cols.at(i)
                if partial == none {
                    panic("Could not determine 'auto' column size for column #" + (i + 1))
                }

                new_cols.at(i) = partial
            }
        }

        let i = 0
        for i in range(new_rows.len()) {
            if new_rows.at(i) == none {
                let partial = partial_rows.at(i)
                if partial == none {
                    panic("Could not determine 'auto' row size for row #" + (i + 1))
                }

                new_rows.at(i) = partial
            }
        }

        (new_cols, new_rows)
    }
}

#let tabular(
    columns: (1pt,), rows: (1pt,),
    inset: 5pt,
    ..items
) = {

}
