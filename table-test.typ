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

#let tabular(columns: (1pt,), rows: (1pt,), inset: 5pt, ..items) = style(styles => {
    let col_len = columns.len();
    let row_len = rows.len();

    if col_len == 0 or row_len == 0 {
        return []
    }

    let items = items.pos()
        .filter(it => it != ())
        .map(it => {
            if type(it) != "dictionary" or not it.keys().contains("tabular_dict_type") {
                tcell[#it]
            } else {
                it
            }
        })

    let grid_size = row_len * col_len

    let has_dtype(it, dtype: none) = (
        type(it) == "dictionary"
        and it.keys().contains("tabular_dict_type")
        and it.tabular_dict_type == dtype
    )

    let has_dtypes(it, dtypes: ()) = (
        type(it) == "dictionary"
        and it.keys().contains("tabular_dict_type")
        and it.tabular_dict_type in dtypes
    )

    let is_valid_cell = has_dtype.with(dtype: "cell")

    let is_hline = has_dtype.with(dtype: "hline")

    let is_vline = has_dtype.with(dtype: "vline")

    let is_some_line = has_dtypes.with(dtypes: ("hline", "vline"))

    let is_occupied = has_dtype.with(dtype: "occupied")

    let cells = items.filter(is_valid_cell)
    let lines = ()

    let positions_spanned_by(cell, x: 0, y: 0) = {
        let result = ()
        let rowspan = cell.rowspan
        let colspan = cell.colspan

        if rowspan < 1 {
            panic("Cell rowspan must be 1 or greater (bad cell: ", (x, y), ")")
        } else if colspan < 1 {
            panic("Cell colspan must be 1 or greater (bad cell: ", (x, y), ")")
        }

        let max_x = calc.min(col_len, x + colspan)
        let max_y = calc.min(row_len, y + rowspan)

        for x in range(x, max_x) {
            for y in range(y, max_y) {
                result.push((x, y))
            }
        }
        // if cell.colspan > 1 { panic(x, result, calc.min(col_len, x + calc.max(0, cell.rowspan))) }
        result
    }

    let n_nones(amount, element: none) = {
        let nones = ()
        for _ in range(0, amount) {
            nones.push(element)
        }
        nones
    }

    let tgrid = ()

    // fill grid with empty arrays
    for _ in range(0, row_len) {
        tgrid.push(n_nones(col_len))
    }

    let grid_at(tgrid, ..pair, lol: "idk") = {
        let pair_pos = pair.pos()
        tgrid.at(pair_pos.at(1)).at(pair_pos.at(0))
    }

    // return the next position available on the grid
    let next_available(tgrid, x: 0, y: 0) = {
        let cell = (x, y)

        while grid_at(tgrid, ..cell) != none {
            x += 1

            if x >= col_len {
                x = 0
                y += 1
            }

            if y >= row_len {
                return none
            }

            cell = (x, y)
        }

        cell
    }

    let default_if_none(x, default) = if x == none {
        default
    } else {
        x
    }

    // for each row/column, a list of cell spans occupying 2+ cells
    let multicell_rows = n_nones(row_len)
    let multicell_cols = n_nones(col_len)

    {
        let prev_x = 0
        let prev_y = 0
        let x = 0
        let y = 0

        for i in range(items.len()) {
            let item = items.at(i)
            if is_some_line(item) {  // set lines' x, y
                if is_hline(item) {
                    item.y = default_if_none(y, row_len)
                } else if is_vline(item) {
                    if prev_y != y {
                        item.x = prev_x + 1  // allow for last line
                    } else {
                        item.x = x
                    }
                } else {
                    panic("Invalid line received (must be hline or vline)")
                }
                items.at(i) = item
                lines.push(item)
            }

            if not is_valid_cell(item) {
                continue
            }

            let cell = item
            if x == none or y == none {
                panic("Some cell is so large that other cells cannot fit, or there are too many cells! Starting at:", (prev_x, prev_y))
            }

            let cell_positions = positions_spanned_by(cell, x: x, y: y)
            let is_multicell = cell_positions.len() > 1

            for position in cell_positions {
                let px = position.at(0)
                let py = position.at(1)
                let currently_there = grid_at(tgrid, px, py)

                if currently_there != none {
                    panic("Error: Conflicting cells", x, y, "|", px, py, tgrid)
                }

                if position == (x, y) {
                    cell.x = x
                    cell.y = y
                    tgrid.at(y).at(x) = cell
                    items.at(i) = cell
                } else {
                    tgrid.at(py).at(px) = occupied(x: x, y: y)
                }

                if is_multicell {
                    let m_row = multicell_rows.at(py)
                    let m_row = if m_row == none { () } else { m_row }

                    let m_col = multicell_cols.at(px)
                    let m_col = if m_col == none { () } else { m_col }

                    if cell.rowspan > 1 and py != y {
                        m_row.push(position)
                        multicell_rows.at(py) = m_row
                    }
                    if cell.colspan > 1 and px != x {
                        m_col.push(position)
                        multicell_cols.at(px) = m_col
                    }

                }
            }

            let next = next_available(tgrid, x: x, y: y)

            prev_x = x
            prev_y = y

            if next == none {
                x = none
                y = none
            } else {
                x = next.at(0)
                y = next.at(1)
            }
        }
    }

    let max_if_not_none(a, b) = if a == none {
        b
    } else if b == none {
        a
    } else {
        calc.max(a, b)
    }

    let cols_rows = {
        if (
            (columns.filter(it => it == auto).len() == 0)
            and (rows.filter(it => it == auto).len() == 0)
        ) {
            (columns, rows)
        } else {
            let cols = columns.map(it => if it == auto { none } else { it })
            let partial_cols = n_nones(col_len)  // for colspans

            let rws = rows.map(it => if it == auto { none } else { it })
            let partial_rws = n_nones(row_len)

            for row in tgrid {
                for cell in row {
                    if cell == none {
                        panic("Not enough cells specified for the given amount of rows and columns.")
                    }
                    if is_occupied(cell) {  // placeholder - ignore
                        continue
                    }
                    let col_count = cell.x
                    let row_count = cell.y
                    if columns.at(col_count) == auto {
                        let measures = measure(cell.content, styles)
                        let width = measures.width
                        if cell.colspan > 1 {  // spans > 1 column => assume 1/n size, unless proven otherwise by another cell
                            partial_cols.at(col_count) = max_if_not_none(width / cell.colspan, partial_cols.at(col_count))
                        } else {
                            cols.at(col_count) = max_if_not_none(width, cols.at(col_count))
                        }
                    }

                    if rows.at(row_count) == auto {
                        let measures = measure(cell.content, styles)
                        let height = measures.height
                        if cell.rowspan > 1 {
                            partial_rws.at(row_count) = max_if_not_none(height, partial_rws.at(row_count))
                        } else {
                            rws.at(row_count) = max_if_not_none(height, rws.at(row_count))
                        }
                    }
                }
            }

            let i = 0
            for i in range(cols.len()) {
                if cols.at(i) == none {
                    let partial = partial_cols.at(i)
                    if partial == none {
                        panic("Could not determine 'auto' column size for column #" + (i + 1))
                    }

                    cols.at(i) = partial
                }
            }

            let i = 0
            for i in range(rws.len()) {
                if rws.at(i) == none {
                    let partial = partial_rws.at(i)
                    if partial == none {
                        panic("Could not determine 'auto' row size for row #" + (i + 1))
                    }

                    rws.at(i) = partial
                }
            }

            (cols, rws)
        }
    }

    let columns = cols_rows.at(0)
    let rows = cols_rows.at(1)

    let cell_width(x, colspan: 1) = {
        let width = columns.at(x) + 2*inset
        for col_width in columns.slice(x, x + colspan) {
            width += col_width
        }
        width
    }

    let cell_height(y, rowspan: 1) = {
        let height = rows.at(y) + 2*inset
        for row_height in rows.slice(y, y + rowspan) {
            height += row_height
        }
        height
    }

    let width_between(start: 0, end: none) = {
        let i = start
        let sum = 0pt
        while i != col_len and i != end {
            sum += columns.at(i) + 2 * inset
            i += 1
        }
        sum
    }

    let height_between(start: 0, end: none) = {
        let i = start
        let sum = 0pt
        while i < row_len and i != end {
            sum += rows.at(i) + 2*inset
            i += 1
        }
        sum
    }

    // return lists of hlines, split up to consider rowspanned cells
    let auto_hlines_between(y, start: 0, end: none) = {
        let lines = ()
        let px = 0
        let x = start
        let max = calc.min(if end == none { col_len } else { end + 1 }, col_len)

        if y == row_len { // at the end
            lines.push(hline(y: y, start: 0, end: col_len))
            return lines
        }

        let multi_positions = multicell_rows.at(y)
        while x < max {

            // check if there is a blocking rowspan at this x
            if (
                multi_positions != none
                and multi_positions.filter(pos => pos.at(0) == x).len() > 0
            ) {
                if px != none {
                    if px != x {
                        lines.push(hline(y: y, start: px, end: x))
                    }
                    px = none
                }
            } else if px == none {
                px = x
            }
            x += 1
        }

        if px != none and px != x {
            lines.push(hline(y: y, start: px, end: x))
        }

        lines
    }

    // panic(multicell_rows, multicell_cols)

    let auto_vlines_between(x, start: 0, end: none) = {
        let lines = ()
        let py = 0
        let y = start
        let max = calc.min(if end == none { row_len } else { end + 1 }, row_len)

        if x == col_len { // at the end
            lines.push(vline(x: x, start: 0, end: row_len))
            return lines
        }

        let multi_positions = multicell_cols.at(x)
        while y < max {

            // check if there is a blocking colspan at this y
            if (
                multi_positions != none
                and multi_positions.filter(pos => pos.at(1) == y).len() > 0
            ) {
                if py != none {
                    if py != y {
                        lines.push(vline(x: x, start: py, end: y))
                    }
                    py = none
                }
            } else if py == none {
                py = y
            }
            y += 1
        }

        if py != none and py != y {
            lines.push(vline(x: x, start: py, end: y))
        }

        lines
    }

    let width = width_between()
    let height = height_between()

    block(width: width, height: height, {
            show line: place.with(top + left)
            let draw_hline(hline) = {
                let start = hline.start
                let end = hline.end
 
                let y = height_between(end: hline.y)
                let start = (width_between(end: start), y)
                let end = (width_between(end: end), y)

                line(start: start, end: end)
            }

            let draw_vline(vline) = {
                let start = vline.start
                let end = vline.end

                let x = width_between(end: vline.x)
                let start = (x, height_between(end: start))
                let end = (x, height_between(end: end))

                line(start: start, end: end)
            }

            for item in items {
                if type(item) != "dictionary" {
                    panic("Invalid table item received (not a dictionary)")
                }
                if not item.keys().contains("tabular_dict_type") {
                    panic("Invalid table item received (does not have table marker key)")
                }

                if item.tabular_dict_type == "cell" {
                    let x = item.x
                    let y = item.y

                    if y >= row_len {
                        panic("Not enough rows specified.")
                    }

                    if x >= col_len {
                        panic("Not enough columns specified.")
                    }

                    let colspan = item.colspan
                    let rowspan = item.rowspan

                    if y + rowspan > row_len + 1 {
                        panic("Cannot rowspan when there are no more rows (cell: ", (x, y), ")")
                    }

                    if x + colspan > col_len + 1 {
                        panic("Cannot colspan when there are no more columns (cell: ", (x, y), ")")
                    }

                    let cw = cell_width(x, colspan: colspan)
                    let ch = cell_height(y, rowspan: rowspan)
                    let item_box = box(
                        width: cw,
                        height: ch,
                        inset: inset,
                        item.content)
                    
                    place(top+left,
                        dx: width_between(end: x),
                        dy: height_between(end: y),
                        item_box)

                } else if item.tabular_dict_type == "hline" {
                    let start = item.start
                    let end = item.end
                    let y = item.y

                    if end == auto {
                        let lines = auto_hlines_between(y, start: start, end: none)
                        for line in lines {
                            draw_hline(line)
                        }
                    } else {
                        draw_hline(item)
                    }
                } else if item.tabular_dict_type == "vline" {
                    let start = item.start
                    let end = item.end
                    let x = item.x
                    
                    if end == auto {
                        let lines = auto_vlines_between(x, start: start, end: none)
                        for line in lines {
                            draw_vline(line)
                        }
                    } else {
                        draw_vline(item)
                    }
                } else {
                    panic("Unknown item type received")
                }
            }
        })

    // block(width: width, height: height, {
    //         show line: place.with(top + left)
    //         let col_count = 0
    //         let row_count = 0
    //         let placed_cells = ()
    //         let next_pos(x, y) = {
    //             let next = if x + 1 == col_len {
    //                 (x + 1, y + 1)
    //             } else if x == col_len {
    //                 (0, y)
    //             } else {
    //                 (x + 1, y)
    //             }
    //             if placed_cells.len() > 0 {
    //                 for cell in placed_cells {
    //                     let nx = next.at(0)
    //                     let ny = next.at(1)
    //                     if (cell.x <= nx
    //                         and cell.x + cell.w >= nx
    //                         and cell.y + cell.h >= ny) {
    //                             panic("what")
    //                             nx += cell.w
    //                             ny += calc.floor(nx / col_count)
    //                             nx = calc.floor(calc.mod(nx, col_count))

    //                             next.at(0) = nx
    //                             next.at(1) = ny
    //                     }
    //                 }
    //             }
    //             next
    //         }
    //         let current_next_pos = (0, 0)  // update partially at the beginning and end of loop
    //         for item in items {
    //             if type(item) != "dictionary" {
    //                 panic("Invalid table item received (not a dictionary)")
    //             }
    //             if not item.keys().contains("tabular_dict_type") {
    //                 panic("Invalid table item received (does not have table marker key)")
    //             }

    //             if item.tabular_dict_type == "cell" {
    //                 current_next_pos = next_pos(col_count, row_count)
    //                 col_count = current_next_pos.at(0)

    //                 if row_count >= row_len {
    //                     panic("Not enough rows specified.")
    //                 }

    //                 let colspan = item.colspan
    //                 let rowspan = item.rowspan

    //                 if row_count + rowspan > row_len {
    //                     panic("Cannot rowspan when there are no more rows")
    //                 }

    //                 if col_count + colspan > col_len {
    //                     panic("Cannot colspan when there are no more columns")
    //                 }

    //                 let cw = cell_width(col_count) * colspan
    //                 let ch = cell_height(row_count) * rowspan
    //                 let item_box = box(
    //                     width: cw + 2*inset,
    //                     height: ch + 2*inset,
    //                     inset: inset,
    //                     [#col_count,#row_count #item.content])
                    
    //                 place(top+left,
    //                     dx: width_between(end: col_count),
    //                     dy: height_between(end: row_count),
    //                     item_box)
                    
    //                 placed_cells.push((
    //                     x: row_count, y: col_count,
    //                     w: colspan, h: rowspan
    //                 ))

    //                 current_next_pos = next_pos(col_count, row_count)

    //                 row_count = current_next_pos.at(1)
    //             } else if item.tabular_dict_type == "hline" {
    //                 let start = item.start;
    //                 let end = item.end;
                    
    //                 let y = if item.y == auto {
    //                     height_between(end: row_count)
    //                 } else {
    //                     item.y
    //                 }
    //                 let start = (width_between(end: start), y)
    //                 let end = (width_between(end: end), y)

    //                 line(start: start, end: end)
    //             } else if item.tabular_dict_type == "vline" {
    //                 let start = item.start;
    //                 let end = item.end;
                    
    //                 place(top+left, (col_count + row_count) * [" "] + [#col_count])
    //                 let x = if item.x == auto {
    //                     width_between(end: col_count)
    //                 } else {
    //                     item.x
    //                 }
    //                 let start = (x, height_between(end: start))
    //                 let end = (x, height_between(end: end))

    //                 line(start: start, end: end)
    //             } else {
    //                 panic("Unknown item type received")
    //             }
    //         }
    //     })
})

#tabular(
    columns: (auto, auto, auto, auto),
    rows: (auto, auto, auto, auto, auto),
    hline(),
    vline(), [a], vline(), [dbddfdddddddd\ f], vline(), [e], vline(), [d], vline(),
    hline(),
    [c], [d], rowspan(length: 2)[c\ e], [d],
    hline(),
    tcell(colspan: 2, rowspan: 2)[This is a huge cell\ very huge indeed], (), (), [d],
    hline(),
    (), (), [h], [e],
    hline(),
    colspan(length: 2)[x], (), [f], [z],
    hline(),
)

