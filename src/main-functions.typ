// #08
// Main rendering functions:
// 1. Calculator of page dimensions.
// 2. Generation and rendering of row groups (rowspans and header).

// -- tablex imports --
#import "common.typ": *
#import "types.typ": *
#import "type-validators.typ": *
#import "utilities.typ": *
#import "grid.typ": *
#import "col-row-size.typ": *
#import "width-height.typ": *
#import "drawing.typ": *
// -- end imports --

// Gets a state variable that holds the page's max x ("width") and max y ("height"),
// considering the left and top margins.
// Requires placing 'get-page-dim-writer(the_returned_state)' on the
// document.
// The id is to differentiate the state for each table.
#let get-page-dim-state(id) = state("tablex_tablex_page_dims__" + repr(id), (width: 0pt, height: 0pt, top_left: none, bottom_right: none))

// A little trick to get the page max width and max height.
// Places a component on the page (or outer container)'s top left,
// and one on the page's bottom right, and subtracts their coordinates.
//
// Must be fed a state variable, which is updated with (width: max x, height: max y).
// The content it returns must be placed in the document for the page state to be
// written to.
//
// NOTE: This function cannot differentiate between the actual page
// and a possible box or block where the component using this function
// could be contained in.
#let get-page-dim-writer() = locate(w_loc => {
    let table_id = _tablex-table-counter.at(w_loc)
    let page_dim_state = get-page-dim-state(table_id)

    place(top + left, locate(loc => {
        page_dim_state.update(s => {
            if s.top_left != none {
                s
            } else {
                let pos = loc.position()
                let width = s.width - pos.x
                let height = s.width - pos.y
                (width: width, height: height, top_left: pos, bottom_right: s.bottom_right)
            }
        })
    }))

    place(bottom + right, locate(loc => {
        page_dim_state.update(s => {
            if s.bottom_right != none {
                s
            } else {
                let pos = loc.position()
                let width = s.width + pos.x
                let height = s.width + pos.y
                (width: width, height: height, top_left: s.top_left, bottom_right: pos)
            }
        })
    }))
})

// Draws a row group using locate() and a block().
#let draw-row-group(
    row-group,
    is-header: false,
    header-pages-state: none,
    first-row-group: none,
    columns: none, rows: none,
    stroke: none,
    gutter: none,
    repeat-header: false,
    styles: none,
    min-pos: none,
    max-pos: none,
    header-hlines-have-priority: true,
    rtl: false,
    table-loc: none,
    total-width: none,
    global-hlines: (),
    global-vlines: (),
) = {
    let width-between = width-between.with(columns: columns, gutter: gutter)
    let height-between = height-between.with(rows: rows, gutter: gutter)
    let draw-hline = draw-hline.with(columns: columns, rows: rows, stroke: stroke, gutter: gutter, vlines: global-vlines, styles: styles)
    let draw-vline = draw-vline.with(columns: columns, rows: rows, stroke: stroke, gutter: gutter, hlines: global-hlines, styles: styles)

    let group-rows = row-group.rows
    let hlines = row-group.hlines
    let vlines = row-group.vlines
    let start-y = row-group.y_span.at(0)
    let end-y = row-group.y_span.at(1)

    locate(loc => {
        // let old_page = latest-page-state.at(loc)
        // let this_page = loc.page()

        // let page_turned = not is-header and old_page not in (this_page, -1)
        let pos = loc.position()
        let page = pos.page
        let rel_page = page - table-loc.page() + 1

        let at_top = pos.y == min-pos.y  // to guard against re-draw issues
        let header_pages = header-pages-state.at(loc)
        let header_count = header_pages.len()
        let page_turned = page not in header_pages

        // draw row group
        block(
            breakable: false,
            fill: none, radius: 0pt, stroke: none,
        {
            let added_header_height = 0pt  // if we added a header, move down

            // page turned => add header
            if page_turned and at_top and not is-header {
                if repeat-header != false {
                    header-pages-state.update(l => l + (page,))
                    if (repeat-header == true) or (type(repeat-header) == _int_type and rel_page <= repeat-header) or (type(repeat-header) == _array_type and rel_page in repeat-header) {
                        let measures = measure(first-row-group.content, styles)
                        place(top+left, first-row-group.content)  // add header
                        added_header_height = measures.height
                    }
                }
            }

            let row_gutter_dy = default-if-none(gutter.row, 0pt)

            // move lines down by the height of the added header
            show line: place.with(top + left, dy: added_header_height)

            let first_x = none
            let first_y = none
            let rightmost_x = none

            let row_heights = 0pt

            let first_row = true
            for row in group-rows {
                if row.len() > 0 {
                    let first_cell = row.at(0)
                    row_heights += rows.at(first_cell.cell.y)
                }
                for cell_box in row {
                    let x = cell_box.cell.x
                    let y = cell_box.cell.y
                    first_x = default-if-none(first_x, x)
                    first_y = default-if-none(first_y, y)
                    rightmost_x = default-if-none(rightmost_x, width-between(start: first_x, end: none))

                    // where to place the cell (horizontally)
                    let dx = width-between(start: first_x, end: x)

                    // TODO: consider implementing RTL before the rendering
                    // stage (perhaps by inverting 'x' positions on cells
                    // and lines beforehand).
                    if rtl {
                        // invert cell's x position (start from the right)
                        dx = rightmost_x - dx
                        // assume the cell doesn't start at the very end
                        // (that would be weird)
                        // Here we have to move dx back a bit as, after
                        // inverting it, it'd be the right edge of the cell;
                        // we need to keep it as the left edge's x position,
                        // as #place works with the cell's left edge.
                        // To do that, we subtract the cell's width from dx.
                        dx -= width-between(start: x, end: x + cell_box.cell.colspan)
                    }

                    // place the cell!
                    place(top+left,
                        dx: dx,
                        dy: height-between(start: first_y, end: y) + added_header_height,
                        cell_box.box)

                    // let box_h = measure(cell_box.box, styles).height
                    // tallest_box_h = calc.max(tallest_box_h, box_h)
                }
                first_row = false
            }

            let row_group_height = row_heights + added_header_height + (row_gutter_dy * group-rows.len())

            let is_last_row = not is-infinite-len(max-pos.y) and pos.y + row_group_height + row_gutter_dy >= max-pos.y

            if is_last_row {
                row_group_height -= row_gutter_dy
                // one less gutter at the end
            }

            hide(rect(width: total-width, height: row_group_height))

            let draw-hline = draw-hline.with(initial_x: first_x, initial_y: first_y, rightmost_x: rightmost_x, rtl: rtl)
            let draw-vline = draw-vline.with(initial_x: first_x, initial_y: first_y, rightmost_x: rightmost_x, rtl: rtl)

            let header_last_y = if first-row-group != none {
                first-row-group.row_group.y_span.at(1)
            } else {
                none
            }
            // if this is the second row, and the header's hlines
            // do not have priority (thus are not drawn by them,
            // otherwise they'd repeat on every page), then
            // we draw its hlines for the header, below it.
            let hlines = if not header-hlines-have-priority and not is-header and start-y == header_last_y + 1 {
                let hlines_below_header = first-row-group.row_group.hlines.filter(h => h.y == header_last_y + 1)

                hlines + hlines_below_header
            } else {
                hlines
            }

            for hline in hlines {
                // only draw the top hline
                // if header's wasn't already drawn
                if hline.y == start-y {
                    let header_last_y = if first-row-group != none {
                        first-row-group.row_group.y_span.at(1)
                    } else {
                        none
                    }
                    // pre-gutter is always false here, as we assume
                    // hlines at the top of this row are handled
                    // at pre-gutter by the preceding row,
                    // and at post-gutter by this (the following) row.
                    // these if's are to check if we should indeed
                    // draw this hline, or if the previous row /
                    // the header should take care of it.
                    if not header-hlines-have-priority and not is-header and start-y == header_last_y + 1 {
                        // second row (after header, and it has no hline priority).
                        draw-hline(hline, pre-gutter: false)
                    } else if hline.y == 0 {
                        // hline at the very top of the table.
                        draw-hline(hline, pre-gutter: false)
                    } else if not page_turned and gutter.row != none and hline.gutter-restrict != top {
                        // this hline, at the top of this row group,
                        // isn't restricted to a pre-gutter position,
                        // so let's draw it right above us.
                        // The page turn check is important:
                        // the hline should not be drawn if the header
                        // was repeated and its own hlines have
                        // priority.
                        draw-hline(hline, pre-gutter: false)
                    } else if page_turned and (added_header_height == 0pt or not header-hlines-have-priority) {
                        draw-hline(hline, pre-gutter: false)
                        // no header repeated, but still at the top of the current page
                    }
                } else {
                    if hline.y == end-y + 1 and (
                        (is-header and not header-hlines-have-priority)
                        or (gutter.row != none and hline.gutter-restrict == bottom)) {
                        // this hline is after all cells
                        // in the row group, and either
                        // this is the header and its hlines
                        // don't have priority (=> the row
                        // groups below it - if repeated -
                        // should draw the hlines above them),
                        // or the hline is restricted to
                        // post-gutter => let the next
                        // row group draw it.
                        continue
                    }

                    // normally, only draw the bottom hlines
                    // (and both their pre-gutter and
                    // post-gutter variations)
                    draw-hline(hline, pre-gutter: true)

                    // don't draw the post-row gutter hline
                    // if this is the last row in the page,
                    // the last row in the row group
                    // (=> the next row group will
                    // place the hline above it, so that
                    // lines break properly between pages),
                    // or the last row in the whole table.
                    if gutter.row != none and hline.y < rows.len() and hline.y < end-y + 1 and not is_last_row {
                        draw-hline(hline, pre-gutter: false)
                    }
                }
            }

            for vline in vlines {
                draw-vline(vline, pre-gutter: true, stop-before-row-gutter: is_last_row)

                // don't draw the post-col gutter vline
                // if this is the last vline
                if gutter.col != none and vline.x < columns.len() {
                    draw-vline(vline, pre-gutter: false, stop-before-row-gutter: is_last_row)
                }
            }
        })
    })
}

// Generates groups of rows.
// By default, 1 row + rows from its rowspan cells = 1 row group.
// The first row group is the header, which is repeated across pages.
#let generate-row-groups(
    grid: none,
    columns: none, rows: none,
    stroke: none, inset: none,
    gutter: none,
    fill: none,
    align: none,
    hlines: none, vlines: none,
    repeat-header: false,
    styles: none,
    header-hlines-have-priority: true,
    min-pos: none,
    max-pos: none,
    header-rows: 1,
    rtl: false,
    table-loc: none,
    table-id: none,
) = {
    let col_len = columns.len()
    let row_len = rows.len()

    // specialize some functions for the given grid, columns and rows
    let v-and-hline-spans-for-cell = v-and-hline-spans-for-cell.with(vlines: vlines, x_limit: col_len, y_limit: row_len, grid: grid)
    let cell-width = cell-width.with(columns: columns, gutter: gutter)
    let cell-height = cell-height.with(rows: rows, gutter: gutter)
    let width-between = width-between.with(columns: columns, gutter: gutter)
    let height-between = height-between.with(rows: rows, gutter: gutter)

    // each row group is an unbreakable unit of rows.
    // In general, they're just one row. However, they can be multiple rows
    // if one of their cells spans multiple rows.
    let first_row_group = none

    let header_pages = state("tablex_tablex_header_pages__" + repr(table-id), (table-loc.page(),))
    let this_row_group = (rows: ((),), hlines: (), vlines: (), y_span: (0, 0))

    let total_width = width-between(end: none)

    let row_group_add_counter = 1  // how many more rows are going to be added to the latest row group
    let current_row = 0
    let header_rows_count = calc.min(row_len, header-rows)

    for row in range(0, row_len) {
        // maximum cell total rowspan in this row
        let max_rowspan = 0

        for column in range(0, col_len) {
            let cell = grid-at(grid, column, row)
            let lines_dict = v-and-hline-spans-for-cell(cell, hlines: hlines)
            let hlines = lines_dict.hlines
            let vlines = lines_dict.vlines

            if is-tablex-cell(cell) {
                // ensure row-spanned rows are in the same group
                row_group_add_counter = calc.max(row_group_add_counter, cell.rowspan)

                let width = cell-width(cell.x, colspan: cell.colspan)
                let height = cell-height(cell.y, rowspan: cell.rowspan)

                let cell_box = make-cell-box(
                    cell,
                    width: width, height: height, inset: inset,
                    align_default: align,
                    fill_default: fill)

                this_row_group.rows.last().push((cell: cell, box: cell_box))

                let hlines = hlines
                    .filter(h =>
                        this_row_group.hlines
                            .filter(is-same-hline.with(h))
                            .len() == 0)

                let vlines = vlines
                    .filter(v => v not in this_row_group.vlines)

                this_row_group.hlines += hlines
                this_row_group.vlines += vlines
            }
        }

        current_row += 1
        row_group_add_counter = calc.max(0, row_group_add_counter - 1)  // one row added
        header_rows_count = calc.max(0, header_rows_count - 1)  // ensure at least the amount of requested header rows was added

        // added all pertaining rows to the group
        // now we can draw it
        if row_group_add_counter <= 0 and header_rows_count <= 0 {
            row_group_add_counter = 1

            let row_group = this_row_group

            // get where the row starts and where it ends
            let start_y = row_group.y_span.at(0)
            let end_y = row_group.y_span.at(1)

            let next_y = end_y + 1

            this_row_group = (rows: ((),), hlines: (), vlines: (), y_span: (next_y, next_y))

            let is_header = first_row_group == none
            let content = draw-row-group(
                row_group,
                is-header: is_header,
                header-pages-state: header_pages,
                first-row-group: first_row_group,
                columns: columns, rows: rows,
                stroke: stroke,
                gutter: gutter,
                repeat-header: repeat-header,
                total-width: total_width,
                table-loc: table-loc,
                header-hlines-have-priority: header-hlines-have-priority,
                rtl: rtl,
                min-pos: min-pos,
                max-pos: max-pos,
                styles: styles,
                global-hlines: hlines,
                global-vlines: vlines,
            )

            if is_header {  // this is now the header group.
                first_row_group = (row_group: row_group, content: content)  // 'content' to repeat later
            }

            (content,)
        } else {
            this_row_group.rows.push(())
            this_row_group.y_span.at(1) += 1
        }
    }
}
