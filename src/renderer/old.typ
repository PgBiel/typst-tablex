// Old rendering functions:
// Generation and rendering of row groups (rowspans and header).

// -- tablex imports --
#import "../common.typ": *
#import "../types.typ": *
#import "../type-validators.typ": *
#import "../utilities.typ": *
#import "../grid.typ": *
#import "../col-row-size.typ": *
#import "../width-height.typ": *
#import "../lines.typ": *
// -- end imports --

#import "./row-groups.typ": generate-row-groups

// Gets a state variable that holds the page's max x ("width") and max y ("height"),
// considering the left and top margins.
// Requires placing 'get-page-dim-writer(the-returned-state)' on the
// document.
// The id is to differentiate the state for each table.
#let get-page-dim-state(id) = state("tablex_tablex_page_dims__" + repr(id), (top-left: none, bottom-right: none))

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
#let get-page-dim-writer(table-loc, table-id) = {
    let page-dim-state = get-page-dim-state(table-id)

    place(top + left, locate(loc => {
        page-dim-state.update(s => {
            if s.top-left != none {
                s
            } else {
                let pos = loc.position()
                (top-left: pos, bottom-right: s.bottom-right)
            }
        })
    }))

    place(bottom + right, locate(loc => {
        page-dim-state.update(s => {
            if s.bottom-right != none {
                s
            } else {
                let pos = loc.position()
                (top-left: s.top-left, bottom-right: pos)
            }
        })
    }))
}

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
    let start-y = row-group.y-span.at(0)
    let end-y = row-group.y-span.at(1)

    locate(loc => {
        // let old-page = latest-page-state.at(loc)
        // let this-page = loc.page()

        // let page-turned = not is-header and old-page not in (this-page, -1)
        let pos = loc.position()
        let page = pos.page
        let rel-page = page - table-loc.page() + 1

        let at-top = pos.y == min-pos.y  // to guard against re-draw issues
        let header-pages = header-pages-state.at(loc)
        let header-count = header-pages.len()
        let page-turned = page not in header-pages

        // draw row group
        block(
            breakable: false,
            fill: none, radius: 0pt, stroke: none,
        {
            let added-header-height = 0pt  // if we added a header, move down

            // page turned => add header
            if page-turned and at-top and not is-header {
                if repeat-header != false {
                    header-pages-state.update(l => l + (page,))
                    if (repeat-header == true) or (type(repeat-header) == _int-type and rel-page <= repeat-header) or (type(repeat-header) == _array-type and rel-page in repeat-header) {
                        let measures = measure(first-row-group.content, styles)
                        place(top+left, first-row-group.content)  // add header
                        added-header-height = measures.height
                    }
                }
            }

            let row-gutter-dy = default-if-none(gutter.row, 0pt)

            let first-x = none
            let first-y = none
            let rightmost-x = none

            let row-heights = 0pt

            let first-row = true
            for row in group-rows {
                if row.len() > 0 {
                    let first-cell = row.at(0)
                    row-heights += rows.at(first-cell.cell.y)
                }
                for cell-box in row {
                    let x = cell-box.cell.x
                    let y = cell-box.cell.y
                    first-x = default-if-none(first-x, x)
                    first-y = default-if-none(first-y, y)
                    rightmost-x = default-if-none(rightmost-x, width-between(start: first-x, end: none))

                    // where to place the cell (horizontally)
                    let dx = width-between(start: first-x, end: x)

                    // TODO: consider implementing RTL before the rendering
                    // stage (perhaps by inverting 'x' positions on cells
                    // and lines beforehand).
                    if rtl {
                        // invert cell's x position (start from the right)
                        dx = rightmost-x - dx
                        // assume the cell doesn't start at the very end
                        // (that would be weird)
                        // Here we have to move dx back a bit as, after
                        // inverting it, it'd be the right edge of the cell;
                        // we need to keep it as the left edge's x position,
                        // as #place works with the cell's left edge.
                        // To do that, we subtract the cell's width from dx.
                        dx -= width-between(start: x, end: x + cell-box.cell.colspan)
                    }

                    // place the cell!
                    place(top+left,
                        dx: dx,
                        dy: height-between(start: first-y, end: y) + added-header-height,
                        cell-box.box)

                    // let box-h = measure(cell-box.box, styles).height
                    // tallest-box-h = calc.max(tallest-box-h, box-h)
                }
                first-row = false
            }

            let row-group-height = row-heights + added-header-height + (row-gutter-dy * group-rows.len())

            let is-last-row = not is-infinite-len(max-pos.y) and pos.y + row-group-height + row-gutter-dy >= max-pos.y

            if is-last-row {
                row-group-height -= row-gutter-dy
                // one less gutter at the end
            }

            hide(rect(width: total-width, height: row-group-height))

            let draw-hline = draw-hline.with(initial-x: first-x, initial-y: first-y, rightmost-x: rightmost-x, rtl: rtl)
            let draw-vline = draw-vline.with(initial-x: first-x, initial-y: first-y, rightmost-x: rightmost-x, rtl: rtl)

            // ensure the lines are drawn absolutely, after the header
            let draw-hline = (..args) => place(top + left, dy: added-header-height, draw-hline(..args))
            let draw-vline = (..args) => place(top + left, dy: added-header-height, draw-vline(..args))

            let header-last-y = if first-row-group != none {
                first-row-group.row-group.y-span.at(1)
            } else {
                none
            }
            // if this is the second row, and the header's hlines
            // do not have priority (thus are not drawn by them,
            // otherwise they'd repeat on every page), then
            // we draw its hlines for the header, below it.
            let hlines = if not header-hlines-have-priority and not is-header and start-y == header-last-y + 1 {
                let hlines-below-header = first-row-group.row-group.hlines.filter(h => h.y == header-last-y + 1)

                hlines + hlines-below-header
            } else {
                hlines
            }

            for hline in hlines {
                // only draw the top hline
                // if header's wasn't already drawn
                if hline.y == start-y {
                    let header-last-y = if first-row-group != none {
                        first-row-group.row-group.y-span.at(1)
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
                    if not header-hlines-have-priority and not is-header and start-y == header-last-y + 1 {
                        // second row (after header, and it has no hline priority).
                        draw-hline(hline, pre-gutter: false)
                    } else if hline.y == 0 {
                        // hline at the very top of the table.
                        draw-hline(hline, pre-gutter: false)
                    } else if not page-turned and gutter.row != none and hline.gutter-restrict != top {
                        // this hline, at the top of this row group,
                        // isn't restricted to a pre-gutter position,
                        // so let's draw it right above us.
                        // The page turn check is important:
                        // the hline should not be drawn if the header
                        // was repeated and its own hlines have
                        // priority.
                        draw-hline(hline, pre-gutter: false)
                    } else if page-turned and (added-header-height == 0pt or not header-hlines-have-priority) {
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
                    if gutter.row != none and hline.y < rows.len() and hline.y < end-y + 1 and not is-last-row {
                        draw-hline(hline, pre-gutter: false)
                    }
                }
            }

            for vline in vlines {
                draw-vline(vline, pre-gutter: true, stop-before-row-gutter: is-last-row)

                // don't draw the post-col gutter vline
                // if this is the last vline
                if gutter.col != none and vline.x < columns.len() {
                    draw-vline(vline, pre-gutter: false, stop-before-row-gutter: is-last-row)
                }
            }
        })
    })
}

#let render-row-groups-old(ctx) = {
    let row-groups = generate-row-groups(ctx)

    let (renderer-ctx, gutter, columns, rows) = ctx

    let cell-width = cell-width.with(columns: columns, gutter: gutter)
    let cell-height = cell-height.with(rows: rows, gutter: gutter)
    let width-between = width-between.with(columns: columns, gutter: gutter)
    let height-between = height-between.with(rows: rows, gutter: gutter)

    // state containing which pages this table's header spans.
    let header-pages = state(
        "tablex_tablex_header_pages__" + repr(renderer-ctx.table-id),
        (renderer-ctx.table-loc.page(),)
    )

    // expected total width between the leftmost and rightmost cells
    let total-width = width-between(end: none)

    // whether we are currently analyzing the first row group (the header).
    let is-header = true

    // store the first row group in a special variable (including its content)
    // used to repeat the header.
    let first-row-group = none

    for group in row-groups {
        group.rows = group.rows.map(cells => cells.map(cell => {
            let width = cell-width(cell.x, colspan: cell.colspan)
            let height = cell-height(cell.y, rowspan: cell.rowspan)

            // create box which contains the cell.
            // this box will contain the appropriate fill for the cell,
            // alongside the cell's inset, alignment and expected size.
            let cell-box = make-cell-box(
                cell,
                width: width,
                height: height,
                inset: ctx.inset,
                align-default: ctx.align,
                fill-default: ctx.fill)

            (cell: cell, box: cell-box)
        }))

        let rendered-group = draw-row-group(
            group,
            is-header: is-header,
            header-pages-state: header-pages,
            first-row-group: first-row-group,
            columns: columns,
            rows: rows,
            stroke: ctx.stroke,
            gutter: ctx.gutter,
            repeat-header: ctx.repeat-header,
            total-width: total-width,
            header-hlines-have-priority: ctx.header-hlines-have-priority,
            rtl: ctx.rtl,
            styles: ctx.styles,
            global-hlines: ctx.hlines,
            global-vlines: ctx.vlines,
            // --- renderer context (defined by the old renderer itself) ---
            table-loc: renderer-ctx.table-loc,
            min-pos: renderer-ctx.min-pos,
            max-pos: renderer-ctx.max-pos,
        )

        if is-header {  // this is now the header group. Store its content
            first-row-group = (row-group: group, content: rendered-group)  // 'content' of the header to repeat later
        }

        is-header = false

        (rendered-group,)
    }
}

// Sets up the old renderer, feeds its context to the table and outputs the table.
// Use as follows:
// old-renderer-setup(size, (renderer-ctx, size, styles) => ... tablex code ...)
#let old-renderer-setup(tablex-callback) = {
    // steps the table counter
    _tablex-table-counter.step()

    locate(loc => {
        // this table's id and position
        // the ID is used to generate unique "state"s, avoiding conflicts with other tables.
        let table-id = _tablex-table-counter.at(loc)
        let table-pos = loc.position()

        // state containing the calculated positions of the edges of the page
        let page-dim-state = get-page-dim-state(table-id)

        // the final value of the state (since the bottom right of the page will be after this table)
        let page-dim = page-dim-state.final(loc)

        // when this element is placed, the page-dim-state will be updated with the coords of the page edges.
        get-page-dim-writer(loc, table-id)

        layout(size => style(styles => {
            let renderer-ctx = (
                table-loc: loc,
                table-id: table-id,
                table-pos: table-pos,
                page-dim: page-dim,

                // try to guess some defaults in case we don't know the page's edges yet:
                // 1. min-pos (normally top left edge): we assume to be the table's position;
                // 2. max-pos (normally bottom right edge): we assume to be the table's position + page size.
                min-pos: default-if-none(page-dim.top-left, table-pos),
                max-pos: default-if-none(page-dim.bottom-right, (x: table-pos.x + size.width, y: table-pos.y + size.height))
            )


            // return the table.
            tablex-callback(renderer-ctx, size, styles)
        }))
    })
}

// Renders the table with the given context dictionary (see renderer.typ).
// Uses the old renderer.
#let render-old(ctx) = {
  // Row groups are blocks of content which are either:
  // 1. A single row.
  // 2. Two or more rows spanned by a rowspan cell. Those rows must stay together (in the same page).
  // 3. Header rows, which must stay together (in the same page).
  let row-groups = render-row-groups-old(ctx)

  // Place the row groups as rows in a grid.
  // The grid will control the pagebreaking aspect.
  // We delegate the job of breaking pages to Typst, therefore.
  grid(columns: (auto,), rows: auto, ..row-groups)
}
