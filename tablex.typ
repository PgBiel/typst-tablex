// Welcome to tablex!
// Feel free to contribute with any features you think are missing.

// -- types --

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

#let tcell(content, fill: auto, align: auto, rowspan: 1, colspan: 1) = (
    tabular_dict_type: "cell",
    content: content,
    rowspan: rowspan,
    colspan: colspan,
    align: align,
    fill: fill,
    x: auto,
    y: auto,
)

#let occupied(x: 0, y: 0, parent_x: none, parent_y: none) = (
    tabular_dict_type: "occupied",
    x: x,
    y: y,
    parent_x: parent_x,
    parent_y: parent_y
)

#let rowspan(content, length: 1, ..cell_options) = tcell(
    content,
    rowspan: length,
    ..cell_options)

#let colspan(content, length: 1, ..cell_options) = tcell(
    content,
    colspan: length,
    ..cell_options)

// -- end: types --

// -- type checks and validators --

// Is this a valid dict created by this library?
#let is_tabular_dict(x) = (
    type(x) == "dictionary"
        and "tabular_dict_type" in x
)

#let is_tabular_dict_type(x, ..dict_types) = (
    is_tabular_dict(x)
        and x.tabular_dict_type in dict_types.pos()
)

#let is_tabular_cell(x) = is_tabular_dict_type(x, "cell")
#let is_tabular_hline(x) = is_tabular_dict_type(x, "hline")
#let is_tabular_vline(x) = is_tabular_dict_type(x, "vline")
#let is_some_tabular_line(x) = is_tabular_dict_type(x, "hline", "vline")
#let is_tabular_occupied(x) = is_tabular_dict_type(x, "occupied")

#let table_item_convert(item, keep_empty: true) = {
    if type(item) == "function" {  // dynamic cell content
        tcell(item)
    } else if keep_empty and item == () {
        item
    } else if type(item) != "dictionary" or "tabular_dict_type" not in item {
        tcell[#item]
    } else {
        item
    }
}

#let validate_cols_rows(columns, rows, items: ()) = {
    if columns != auto and type(columns) != "array" {
        panic("Columns must be either 'auto' or an array of sizes (or 'auto's).")
    }
    
    if rows != auto and type(rows) != "array" {
        panic("Rows must be either 'auto' or an array of sizes (or 'auto's).")
    }

    let grid_len() = {
        let len = 0

        for item in items {
            // cell occupies (colspan * rowspan) spaces
            if is_tabular_cell(item) {
                len += item.colspan * item.rowspan
            } else if type(item) == "content" {
                len += 1
            }
        }

        len
    }

    if columns == auto {
        if rows == auto {
            columns = (auto,)  // assume 1 column and many rows

            rows = (auto,) * grid_len()
        } else {
            // ceil to allow incomplete columns
            columns = (auto,) * calc.ceil(grid_len() / rows.len())
        }
    } else if rows == auto {
        // ceil to allow incomplete rows
        rows = (auto,) * calc.ceil(grid_len() / columns.len())
    }

    (columns: columns, rows: rows)
}

// -- end: type checks and validators --

// -- utility functions --

// Which positions does a cell occupy
// (Usually just its own, but increases if colspan / rowspan
// is greater than 1)
#let positions_spanned_by(cell, x: 0, y: 0, x_limit: 0, y_limit: 0) = {
    let result = ()
    let rowspan = if "rowspan" in cell { cell.rowspan } else { 1 }
    let colspan = if "colspan" in cell { cell.colspan } else { 1 }

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
#let max_if_not_none(a, b) = if a in (none, auto) {
    b
} else if b in (none, auto) {
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
#let next_available_position(
    grid, x: 0, y: 0, x_limit: 0, y_limit: 0
) = {
    let cell = (x, y)
    let there_is_next(cell_pos) = {
        let grid_cell = grid_at(grid, ..cell_pos)
        grid_cell != none
    }

    while there_is_next(cell) {
        x += 1

        if x >= x_limit {
            x = 0
            y += 1
        }

        if y >= y_limit {  // last row reached - stop
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

    // go through all input
    for i in range(items.len()) {
        let item = items.at(i)

        if type(item) == "array" and item.len() == 0 {
            if x == 0 and y == 0 {  // increment vline's secondary counter
                prev_x += 1

                if prev_x > x_limit {
                    panic("Error: Specified way too many empty cells before the first row of the table. Please specify at most " + str(x_limit) + " empty cells or vlines
                    on the first row.")
                }
            }

            continue
        }

        let item = table_item_convert(item)


        if is_some_tabular_line(item) {  // detect lines' x, y
            if is_tabular_hline(item) {
                item.y = default_if_none(item.y, default_if_none(y, y_limit), forbidden: auto)

                hlines.push(item)
            } else if is_tabular_vline(item) {
                if item.x == auto {
                    if x == 0 and y == 0 {  // placed before any elements
                        item.x = prev_x
                        prev_x += 1  // use this as a 'secondary counter'
                                     // in the meantime

                        if prev_x > x_limit + 1 {
                            panic("Error: Specified way too many empty cells before the first row of the table. Please specify at most " + str(x_limit + 1) + " empty cells or vlines on the first row.")
                        }
                    } else if row_wrapped {
                        item.x = x_limit  // allow v_line at the last column
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
        if x == none or y == none {
            panic("Attempted to add cells with no space available! Maybe there are too many cells? Failing cell's position:", (prev_x, prev_y), " Rows/columns available:", (y_limit, x_limit))
        }

        let cell_positions = positions_spanned_by(cell, x: x, y: y, x_limit: x_limit, y_limit: y_limit)

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
                grid.at(py).at(px) = occupied(x: px, y: py, parent_x: x, parent_y: y)  // signal parent cell
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
        items: items,
        hlines: hlines,
        vlines: vlines
    )
}

// Determine the size of 'auto' columns and rows
#let determine_auto_column_row_sizes(grid: (), styles: none, columns: none, rows: none) = {
    if auto not in columns and auto not in rows {
        (
            columns: columns,
            rows: rows
        )  // no action necessary if no auto's are present
    } else {
        let new_cols = columns.slice(0)
        let new_rows = rows.slice(0)

        for row in grid {
            for cell in row {
                if cell == none {
                    panic("Not enough cells specified for the given amount of rows and columns.")
                }
                if is_tabular_occupied(cell) {  // placeholder - ignore
                    continue
                }

                let col_count = cell.x
                let row_count = cell.y

                if "colspan" not in cell { panic(cell) }
                let affected_auto_columns = range(cell.x, cell.x + cell.colspan).filter(c => columns.at(c) == auto)

                let affected_auto_rows = range(cell.y, cell.y + cell.rowspan).filter(r => rows.at(r) == auto)

                let auto_col_amount = affected_auto_columns.len()  // auto columns spanned by this cell (up to 1 if colspan is 1)
                let auto_row_amount = affected_auto_rows.len()  // same but for rows

                if auto_col_amount > 0 {
                    let measures = measure(cell.content, styles)
                    let width = measures.width / auto_col_amount  // resize auto columns proportionately, to fit the cell

                    for auto_column in affected_auto_columns {
                        new_cols.at(auto_column) = max_if_not_none(width, new_cols.at(auto_column))
                    }
                }

                if auto_row_amount > 0 {
                    let measures = measure(cell.content, styles)
                    let height = measures.height / auto_row_amount  // resize auto rows proportionately, to fit the cell

                    for auto_row in affected_auto_rows {
                        new_rows.at(auto_row) = max_if_not_none(height, new_rows.at(auto_row))
                    }
                    // panic(measures, height, new_rows)
                }
            }
        }

        (
            columns: new_cols,
            rows: new_rows
        )
    }
}

// if occupied => get the cell that generated it.
// if a cell => return it, untouched.
#let get_parent_cell(cell, grid: none) = {
    if is_tabular_occupied(cell) {
        grid_at(grid, cell.parent_x, cell.parent_y)
    } else if is_tabular_cell(cell) {
        cell
    } else {
        panic("Cannot get parent table cell of a non-cell object.")
    }
}

// -- end: grid functions --

// -- width/height utilities --

#let width_between(start: 0, end: none, columns: (), inset: 5pt) = {
    end = default_if_none(end, columns.len())

    let sum = 0pt
    for i in range(start, calc.min(columns.len() + 1, end)) {
        sum += columns.at(i) + 2 * inset
    }
    sum
}

#let height_between(start: 0, end: none, rows: (), inset: 5pt) = {
    end = default_if_none(end, rows.len())

    let sum = 0pt
    for i in range(start, calc.min(rows.len() + 1, end))  {
        sum += rows.at(i) + 2*inset
    }
    sum
}

#let cell_width(x, colspan: 1, columns: (), inset: 5pt) = {
    // let width = 2*inset
    // for col_width in columns.slice(x, x + colspan) {
    //     width += col_width
    // }
    // width
    width_between(start: x, end: x + colspan, columns: columns, inset: inset)
}

#let cell_height(y, rowspan: 1, rows: (), inset: 5pt) = {
    // let height = 2*inset
    // for row_height in rows.slice(y, y + rowspan) {
    //     height += row_height
    // }
    // height
    height_between(start: y, end: y + rowspan, rows: rows, inset: inset)
}

// overide start and end for vlines and hlines (keep styling options and stuff)
#let v_or_hline_with_span(v_or_hline, start: none, end: none) = {
    (
        ..v_or_hline,
        start: start,
        end: end
    )
}

// check the subspan a hline or vline goes through inside a larger span
#let get_included_span(l_start, l_end, start: 0, end: 0, limit: 0) = {
    if l_start in (none, auto) {
        l_start = 0
    }

    if l_end in (none, auto) {
        l_end = limit
    }

    l_start = calc.max(0, l_start)
    l_end = calc.min(end, limit)

    // ---- ====     or ==== ----
    if l_end < start or l_start > end {
        return none
    }

    // --##==   ;   ==##-- ;  #### ; ... : intersection.
    (calc.max(l_start, start), calc.min(l_end, end))
}

// restrict hlines and vlines to the cells' borders.
// i.e.
//                | (vline)
//                |
// (hline) ----====---      (= and || indicate intersection)
//             |  ||
//             ----   <--- sample cell
#let v_and_hline_spans_for_cell(cell, hlines: (), vlines: (), x_limit: 0, y_limit: 0, grid: ()) = {
    let parent_cell = get_parent_cell(cell, grid: grid)

    if parent_cell != cell and parent_cell.colspan <= 1 and parent_cell.rowspan <= 1 {
        panic("Bad parent cell: ", (parent_cell.x, parent_cell.y), " cannot be a parent of ", (cell.x, cell.y), ": it only occupies one cell slot.")
    }

    let hlines = hlines
        .filter(h => {
            let y = h.y

            ((y in (cell.y, cell.y + 1, y_limit)
                and (y != cell.y or parent_cell.y >= cell.y)  // only show top line if parent cell isn't strictly above
                and (y != cell.y + 1 or ((parent_cell.y + parent_cell.rowspan - 1 <= cell.y) and (parent_cell.rowspan < 2)))) // only show bottom line if end of rowspan isn't below
                and (h.end in (auto, none) or h.end >= cell.x + 1))
                // ^ don't go beyond the hline's end
        })
        .map(h => {
            // get the intersection between the hline and the cell's x-span.
            let span = get_included_span(h.start, h.end, start: cell.x, end: cell.x + 1, limit: x_limit)
            v_or_hline_with_span(h, start: span.at(0), end: span.at(1))
        })

    let vlines = vlines
        .filter(v => {
            let x = v.x

            ((x in (cell.x, cell.x + 1, x_limit))
                and (x != cell.x or parent_cell.x >= cell.x)  // only show left line if parent cell isn't strictly to the left
                and (x != cell.x + 1 or ((parent_cell.x + parent_cell.colspan - 1 <= cell.x) and (parent_cell.colspan < 2)))
                and (v.end in (auto, none) or v.end >= cell.y + 1))
                // ^ don't go beyond the vline's end
        })  // only show right line if end of colspan isn't to the right
        .map(v => {
            // get the intersection between the hline and the cell's x-span.
            let span = get_included_span(v.start, v.end, start: cell.y, end: cell.y + 1, limit: y_limit)
            v_or_hline_with_span(v, start: span.at(0), end: span.at(1))
        })

    (
        hlines: hlines,
        vlines: vlines
    )
}

// Are two hlines the same?
// (Check to avoid double drawing)
#let is_same_hline(a, b) = (
    is_tabular_hline(a)
        and is_tabular_hline(b)
        and a.y == b.y
        and a.start == b.start
        and a.end == b.end
)

// -- end: width/height utilities --

// -- drawing --

#let draw_hline(hline, initial_x: 0, initial_y: 0, columns: (), rows: ()) = {
    let start = hline.start
    let end = hline.end

    let y = height_between(start: initial_y, end: hline.y, rows: rows)
    let start = (width_between(start: initial_x, end: start, columns: columns), y)
    let end = (width_between(start: initial_x, end: end, columns: columns), y)

    line(start: start, end: end)
}

#let draw_vline(vline, initial_x: 0, initial_y: 0, columns: (), rows: ()) = {
    let start = vline.start
    let end = vline.end

    let x = width_between(start: initial_x, end: vline.x, columns: columns)
    let start = (x, height_between(start: initial_y, end: start, rows: rows))
    let end = (x, height_between(start: initial_y, end: end, rows: rows))

    line(start: start, end: end)
}

// Makes a cell's box, using the given options
// cell - The cell data (including content)
// width, height - The cell's dimensions
// inset - The table's inset
// align_default - The default alignment if the cell doesn't specify one
// fill_default - The default fill color / etc if the cell doesn't specify one
#let make_cell_box(
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

    // use default align (specified in
    // table 'align:')
    // when the cell align is 'auto'
    let cell_align = default_if_none(cell.align, align_default, forbidden: auto)

    // same here for fill
    let cell_fill = default_if_none(cell.fill, fill_default, forbidden: auto)

    if cell_align != auto and type(cell_align) not in ("alignment", "2d alignment") {
        panic("Invalid alignment specified (must be either a function (row, column) -> alignment, an alignment value - such as 'left' or 'center + top' -, or 'auto').")
    }

    let aligned_cell_content = if cell_align == auto {
        [#cell.content]
    } else {
        align(cell_align)[#cell.content]
    }

    box(width: width, height: height, inset: inset, fill: cell_fill,
        aligned_cell_content)
}

// -- end: drawing

#let tabular(
    columns: auto, rows: auto,
    inset: 5pt,
    align: auto,
    fill: none,
    ..items
) = {
    let page_dimensions = state("tablex_tabular_page_dims", (width: 0pt, height: 0pt))

    // A little hack to get the page max width and max height
    place(bottom+right, locate(loc => {
        let pos = loc.position()
        let width = pos.x
        let height = pos.y
        page_dimensions.update(p => (width: width, height: height))
    }))

    locate(t_loc => style(styles => {
        let page_dim_at = page_dimensions.at(t_loc)
        let t_pos = t_loc.position()

        // Subtract the max width/height from current width/height to disregard margin/etc.
        let page_width = page_dim_at.width - t_pos.x
        let page_height = page_dim_at.height - t_pos.y

        let initial_items = items.pos().map(table_item_convert)
        let items = initial_items.filter(x => x != ())

        let validated_cols_rows = validate_cols_rows(
            columns, rows, items: items.filter(is_tabular_cell))

        let col_len = validated_cols_rows.columns.len()
        let row_len = validated_cols_rows.rows.len()

        // fill in the blanks
        let items_len = items.len()
        if items_len < col_len * row_len {
            items += ([],) * (col_len * row_len - items_len)
            items += ([],) * (col_len * row_len - items_len)
        }
        let items_len = items.len()

        // generate cell matrix and other things
        let grid_info = generate_grid(initial_items, x_limit: col_len, y_limit: row_len)

        let table_grid = grid_info.grid
        let hlines = grid_info.hlines
        let vlines = grid_info.vlines
        let items = grid_info.items

        // convert auto to actual size
        let updated_cols_rows = determine_auto_column_row_sizes(
            grid: table_grid, styles: styles,
            columns: validated_cols_rows.columns, rows: validated_cols_rows.rows)

        let columns = updated_cols_rows.columns
        let rows = updated_cols_rows.rows

        // specialize some functions for the given grid, columns and rows
        let get_parent_cell = get_parent_cell.with(grid: grid)
        let v_and_hline_spans_for_cell = v_and_hline_spans_for_cell.with(vlines: vlines, x_limit: col_len, y_limit: row_len, grid: table_grid)
        let cell_width = cell_width.with(columns: columns, inset: inset)
        let cell_height = cell_height.with(rows: rows, inset: inset)
        let width_between = width_between.with(columns: columns, inset: inset)
        let height_between = height_between.with(rows: rows, inset: inset)
        let draw_hline = draw_hline.with(columns: columns, rows: rows)
        let draw_vline = draw_vline.with(columns: columns, rows: rows)

        // each row group is an unbreakable unit of rows.
        // In general, they're just one row. However, they can be multiple rows
        // if one of their cells spans multiple rows.
        let first_row_group = none

        // page in the latest row group
        let latest_page = state("tablex_tabular_latest_page", -1)

        // don't draw hlines twice
        let drawn_hlines = state("tablex_tabular_drawn_hlines", ((), (), (), (), (), ()))
        let pages_with_header = state("tablex_tabular_pages_with_header", (1,))
        let this_row_group = (rows: ((),), hlines: (), vlines: (), y_span: (0, 0))

        let total_width = width_between(end: none)

        let row_groups = {
            let row_group_add_counter = 1  // how many more rows are going to be added to the latest row group
            let current_row = 0
            for row in table_grid {
                let hlines = hlines.filter(h => h.y in (current_row, current_row + 1))  // hlines between this row and the next

                for cell in row {
                    let lines_dict = v_and_hline_spans_for_cell(cell, hlines: hlines)
                    let hlines = lines_dict.hlines
                    let vlines = lines_dict.vlines


                    if is_tabular_cell(cell) and cell.rowspan > 1 {
                        // ensure row-spanned rows are in the same group
                        row_group_add_counter += cell.rowspan - 1
                    }

                    if is_tabular_cell(cell) {
                        let width = cell_width(cell.x, colspan: cell.colspan)
                        let height = cell_height(cell.y, rowspan: cell.rowspan)

                        if cell.rowspan > 1 {
                            // panic(height, cell, table_grid)
                        }

                        let cell_box = make_cell_box(
                            cell,
                            width: width, height: height, inset: inset,
                            align_default: align,
                            fill_default: fill)

                        this_row_group.rows.last().push((cell: cell, box: cell_box))
                    }

                    let hlines = hlines.filter(h =>
                        this_row_group.hlines.filter(is_same_hline.with(h))
                            .len() == 0)

                    let vlines = vlines.filter(v =>
                        v not in this_row_group.vlines)

                    this_row_group.hlines += hlines
                    this_row_group.vlines += vlines
                }

                current_row += 1
                row_group_add_counter -= 1

                // added all pertaining rows to the group
                // now we can draw it
                if row_group_add_counter <= 0 {
                    row_group_add_counter = 1

                    let row_group = this_row_group

                    let rows = row_group.rows
                    let hlines = row_group.hlines
                    let vlines = row_group.vlines

                    // get where the row starts and where it ends
                    let start_y = row_group.y_span.at(0)
                    let end_y = row_group.y_span.at(1)

                    let next_y = end_y + 1

                    this_row_group = (rows: ((),), hlines: (), vlines: (), y_span: (next_y, next_y))


                    let row_group_content(is_first: false) = locate(loc => {
                        let old_page = latest_page.at(loc)
                        let this_page = loc.page()



                        let page_turned = not is_first and old_page != this_page

                        block(breakable: false, {
                            let added_header_height = 0pt  // if we added a header, move down

                            if page_turned and this_page not in pages_with_header.at(loc) {
                                let measures = measure(first_row_group.content, styles)
                                place(top+left, first_row_group.content)  // add header
                                added_header_height = measures.height

                                // do not place the header again on this page
                                pages_with_header.update(l => l + (this_page,))
                            }

                            // move lines down by the height of the header
                            show line: place.with(top + left, dy: added_header_height)

                            let first_x = none
                            let first_y = none

                            let tallest_box_h = 0pt;
                            let tallest_box = [];

                            let first_row = true
                            for row in rows {
                                for cell_box in row {
                                    let x = cell_box.cell.x
                                    let y = cell_box.cell.y
                                    first_x = default_if_none(first_x, x)
                                    first_y = default_if_none(first_y, y)

                                    place(top+left,
                                        dx: width_between(start: first_x, end: x),
                                        dy: height_between(start: first_y, end: y) + added_header_height,
                                        cell_box.box)

                                    let box_h = measure(cell_box.box, styles).height
                                    if box_h > tallest_box_h {
                                        tallest_box_h = box_h
                                        tallest_box = cell_box.box
                                    }
                                }
                                first_row = false
                            }

                            hide(rect(width: total_width, height: tallest_box_h + added_header_height))

                            for hline in hlines {
                                let drawn_hlines_at = drawn_hlines.at(loc)
                                if (page_turned and drawn_hlines_at.len() <= this_page - 1) or drawn_hlines_at.at(this_page - 1).filter(is_same_hline.with(hline)).len() == 0 {
                                    draw_hline(hline, initial_x: first_x, initial_y: first_y)
                                    drawn_hlines.update(l => {
                                        while l.len() <= this_page - 1 {
                                            l.push(())
                                        }
                                        l.at(this_page - 1).push(hline)
                                        l
                                    })
                                }
                            }

                            for vline in vlines {
                                draw_vline(vline, initial_x: first_x, initial_y: first_y)
                            }
                        })

                        latest_page.update(calc.max.with(this_page))  // don't change the page if it is already larger than ours
                    })

                    let is_first = first_row_group == none
                    let content = row_group_content(is_first: is_first)

                    if is_first {
                        first_row_group = (row_group: row_group, content: content)
                    }

                    (content,)
                } else {
                    this_row_group.rows.push(())
                    this_row_group.y_span.at(1) += 1
                }
            }
        }

        grid(columns: (auto,), rows: auto, ..row_groups)
}))}
