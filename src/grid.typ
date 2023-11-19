// #04
// Functions related to tablex's internal grid generation.
// The internal grid is the table's internal representation,
// a.k.a. a matrix of cells, flattened into an 1D array
// for efficiency
// (which is fine since the number of columns is fixed:
// there is one row at every '# of columns' cells).

// -- tablex imports --
#import "common.typ": *
#import "types.typ": *
#import "type-validators.typ": *
#import "utilities.typ": *
// -- end imports --

#let create-grid(width, initial_height) = (
    tablex-dict-type: "grid",
    items: init-array(width * initial_height),
    width: width
)

#let is-tablex-grid(value) = is-tablex-dict-type("grid")

// Gets the index of (x, y) in a grid's array.
#let grid-index-at(x, y, grid: none, width: none) = {
    width = default-if-none(grid, (width: width)).width
    width = calc.floor(width)
    (y * width) + calc-mod(x, width)
}

// Gets the cell at the given grid x, y position.
// Width (amount of columns) per line must be known.
// E.g. grid-at(grid, 5, 2, width: 7)  => 5th column, 2nd row  (7 columns per row)
#let grid-at(grid, x, y) = {
    let index = grid-index-at(x, y, width: grid.width)

    if index < grid.items.len() {
        grid.items.at(index)
    } else {
        none
    }
}

// Returns 'true' if the cell at (x, y)
// exists in the grid.
#let grid-has-pos(grid, x, y) = (
    grid-index-at(x, y, grid: grid) < grid.items.len()
)

// How many rows are in this grid? (Given its width)
#let grid-count-rows(grid) = (
    calc.floor(grid.items.len() / grid.width)
)

// Converts a grid array index to (x, y)
#let grid-index-to-pos(grid, index) = (
    (calc-mod(index, grid.width), calc.floor(index / grid.width))
)

// Fetches an entire row of cells (all positions with the given y).
#let grid-get-row(grid, y) = {
    range(grid.width).map(x => grid-at(grid, x, y))
}

// Fetches an entire column of cells (all positions with the given x).
#let grid-get-column(grid, x) = {
    range(grid-count-rows(grid)).map(y => grid-at(grid, x, y))
}

// Expand grid to the given coords (add the missing cells)
#let grid-expand-to(grid, x, y, fill_with: (grid) => none) = {
    let rows = grid-count-rows(grid)
    let rowws = rows

    // quickly add missing rows
    while rows < y {
        grid.items += (fill_with(grid),) * grid.width
        rows += 1
    }

    let now = grid-index-to-pos(grid, grid.items.len() - 1)
    // now columns and/or last missing row
    while not grid-has-pos(grid, x, y) {
        grid.items.push(fill_with(grid))
    }
    let new = grid-index-to-pos(grid, grid.items.len() - 1)

    grid
}

// if occupied (extension of a cell) => get the cell that generated it.
// if a normal cell => return it, untouched.
#let get-parent-cell(cell, grid: none) = {
    if is-tablex-occupied(cell) {
        grid-at(grid, cell.parent-x, cell.parent-y)
    } else if is-tablex-cell(cell) {
        cell
    } else {
        panic("Cannot get parent table cell of a non-cell object: " + repr(cell))
    }
}

// Return the next position available on the grid
#let next-available-position(
    grid, x: 0, y: 0, x-limit: 0, y-limit: 0
) = {
    let cell = (x, y)
    let there_is_next(cell_pos) = {
        let grid_cell = grid-at(grid, ..cell_pos)
        grid_cell != none
    }

    while there_is_next(cell) {
        x += 1

        if x >= x-limit {
            x = 0
            y += 1
        }

        cell = (x, y)

        if y >= y-limit {  // last row reached - stop
            break
        }
    }

    cell
}

// Organize cells in a grid from the given items,
// and also get all given lines
#let generate-grid(items, x-limit: 0, y-limit: 0, map-cells: c => c) = {
    // init grid as a matrix
    // y-limit  x   x-limit
    let grid = create-grid(x-limit, y-limit)

    let grid-index-at = grid-index-at.with(width: x-limit)

    let hlines = ()
    let vlines = ()

    let prev_x = 0
    let prev_y = 0

    let x = 0
    let y = 0

    let first_cell_reached = false  // if true, hline should always be placed after the current row
    let row_wrapped = false  // if true, a vline should be added to the end of a row

    let range_of_items = range(items.len())

    let new_empty_cell(grid, index: auto) = {
        let empty_cell = cellx[]
        let index = default-if-auto(index, grid.items.len())
        let new_cell_pos = grid-index-to-pos(grid, index)
        empty_cell.x = new_cell_pos.at(0)
        empty_cell.y = new_cell_pos.at(1)

        empty_cell
    }

    // go through all input
    for i in range_of_items {
        let item = items.at(i)

        // allow specifying () to change vline position
        if type(item) == _array_type and item.len() == 0 {
            if x == 0 and y == 0 {  // increment vline's secondary counter
                prev_x += 1
            }

            continue  // ignore all '()'
        }

        let item = table-item-convert(item)


        if is-some-tablex-line(item) {  // detect lines' x, y
            if is-tablex-hline(item) {
                let this_y = if first_cell_reached {
                    prev_y + 1
                } else {
                    prev_y
                }

                item.y = default-if-auto(item.y, this_y)

                hlines.push(item)
            } else if is-tablex-vline(item) {
                if item.x == auto {
                    if x == 0 and y == 0 {  // placed before any elements
                        item.x = prev_x
                        prev_x += 1  // use this as a 'secondary counter'
                                     // in the meantime

                        if prev_x > x-limit + 1 {
                            panic("Error: Specified way too many vlines or empty () cells before the first row of the table. (Note that () is used to separate vline()s at the beginning of the table.)  Please specify at most " + str(x-limit + 1) + " empty cells or vlines before the first cell of the table.")
                        }
                    } else if row_wrapped {
                        item.x = x-limit  // allow v_line at the last column
                        row_wrapped = false
                    } else {
                        item.x = x
                    }
                }

                vlines.push(item)
            } else {
                panic("Invalid line received (must be hline or vline).")
            }
            items.at(i) = item  // override item with the new x / y coord set
            continue
        }

        let cell = item

        assert(is-tablex-cell(cell), message: "All table items must be cells or lines.")

        first_cell_reached = true

        let this_x = default-if-auto(cell.x, x)
        let this_y = default-if-auto(cell.y, y)

        if cell.x == none or cell.y == none {
            panic("Error: Received cell with 'none' as x or y.")
        }

        if this_x == none or this_y == none {
            panic("Internal tablex error: Grid wasn't large enough to fit the given cells. (Previous position: " + repr((prev_x, prev_y)) + ", new cell: " + repr(cell) + ")")
        }

        cell.x = this_x
        cell.y = this_y
        cell = table-item-convert(map-cells(cell))

        assert(is-tablex-cell(cell), message: "Tablex error: 'map-cells' returned something that isn't a valid cell.")

        if row_wrapped {
            row_wrapped = false
        }

        let content = cell.content
        let content = if type(content) == _function_type {
            let res = content(this_x, this_y)
            if is-tablex-cell(res) {
                cell = res
                this_x = cell.x
                this_y = cell.y
                [#res.content]
            } else {
                [#res]
            }
        } else {
            [#content]
        }

        if this_x == none or this_y == none {
            panic("Error: Cell with function as content returned another cell with 'none' as x or y!")
        }

        if type(this_x) != _int_type or type(this_y) != _int_type {
            panic("Error: Cell coordinates must be integers. Invalid pair: " + repr((this_x, this_y)))
        }

        cell.content = content

        // up to which 'y' does this cell go
        let max_x = this_x + cell.colspan - 1
        let max_y = this_y + cell.rowspan - 1

        if this_x >= x-limit {
            panic("Error: Cell at " + repr((this_x, this_y)) + " is placed at an inexistent column.")
        }

        if max_x >= x-limit {
            panic("Error: Cell at " + repr((this_x, this_y)) + " has a colspan of " + repr(cell.colspan) + ", which would exceed the available columns.")
        }

        let cell_positions = positions-spanned-by(cell, x: this_x, y: this_y, x-limit: x-limit, y-limit: none)

        for position in cell_positions {
            let px = position.at(0)
            let py = position.at(1)
            let currently_there = grid-at(grid, px, py)

            if currently_there != none {
                let parent_cell = get-parent-cell(currently_there, grid: grid)

                panic("Error: Multiple cells attempted to occupy the cell position at " + repr((px, py)) + ": one starting at " + repr((this_x, this_y)) + ", and one starting at " + repr((parent_cell.x, parent_cell.y)))
            }

            // initial position => assign it to the cell's x/y
            if position == (this_x, this_y) {
                cell.x = this_x
                cell.y = this_y

                // expand grid to allow placing this cell (including colspan / rowspan)
                let grid_expand_res = grid-expand-to(grid, grid.width - 1, max_y)

                grid = grid_expand_res
                y-limit = grid-count-rows(grid)

                let index = grid-index-at(this_x, this_y)

                if index > grid.items.len() {
                    panic("Internal tablex error: Could not expand grid to include cell at " + repr((this_x, this_y)))
                }
                grid.items.at(index) = cell
                items.at(i) = cell

            // other secondary position (from colspan / rowspan)
            } else {
                let index = grid-index-at(px, py)

                grid.items.at(index) = occupied(x: px, y: py, parent-x: this_x, parent-y: this_y)  // indicate this position's parent cell (to join them later)
            }
        }

        let next_pos = next-available-position(grid, x: this_x, y: this_y, x-limit: x-limit, y-limit: y-limit)

        prev_x = this_x
        prev_y = this_y

        x = next_pos.at(0)
        y = next_pos.at(1)

        if prev_y != y {
            row_wrapped = true  // we changed rows!
        }
    }

    // for missing cell positions: add empty cell
    for index_item in enumerate(grid.items) {
        let index = index_item.at(0)
        let item = index_item.at(1)
        if item == none {
            grid.items.at(index) = new_empty_cell(grid, index: index)
        }
    }

    // while there are incomplete rows for some reason, add empty cells
    while calc-mod(grid.items.len(), grid.width) != 0 {
        grid.items.push(new_empty_cell(grid))
    }

    (
        grid: grid,
        items: grid.items,
        hlines: hlines,
        vlines: vlines,
        new-row-count: grid-count-rows(grid)
    )
}
