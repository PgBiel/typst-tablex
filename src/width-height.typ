// #06
// Utility functions for calculating width and height between parts of the table,
// and also for breaking down lines to their intersections with cells.

// -- tablex imports --
#import "common.typ": *
#import "types.typ": *
#import "type-validators.typ": *
#import "utilities.typ": *
// -- end imports --

#let width-between(start: 0, end: none, columns: (), gutter: none, pre-gutter: false) = {
    let col-gutter = default-if-none(default-if-none(gutter, (col: 0pt)).col, 0pt)
    end = default-if-none(end, columns.len())

    let col-range = range(start, calc.min(columns.len() + 1, end))

    let sum = 0pt
    for i in col-range {
        sum += columns.at(i) + col-gutter
    }

    // if the end is after all columns, there is
    // no gutter at the end.
    if pre-gutter or end == columns.len() {
        sum = calc.max(0pt, sum - col-gutter) // remove extra gutter from last col
    }

    sum
}

#let height-between(start: 0, end: none, rows: (), gutter: none, pre-gutter: false) = {
    let row-gutter = default-if-none(default-if-none(gutter, (row: 0pt)).row, 0pt)
    end = default-if-none(end, rows.len())

    let row-range = range(start, calc.min(rows.len() + 1, end))

    let sum = 0pt
    for i in row-range {
        sum += rows.at(i) + row-gutter
    }

    // if the end is after all rows, there is
    // no gutter at the end.
    if pre-gutter or end == rows.len() {
        sum = calc.max(0pt, sum - row-gutter) // remove extra gutter from last row
    }

    sum
}

#let cell-width(x, colspan: 1, columns: (), gutter: none) = {
    width-between(start: x, end: x + colspan, columns: columns, gutter: gutter, pre-gutter: true)
}

#let cell-height(y, rowspan: 1, rows: (), gutter: none) = {
    height-between(start: y, end: y + rowspan, rows: rows, gutter: gutter, pre-gutter: true)
}

// override start and end for vlines and hlines (keep styling options and stuff)
#let v-or-hline-with-span(v-or-hline, start: none, end: none) = {
    (
        ..v-or-hline,
        start: start,
        end: end,
        parent: v-or-hline  // the one that generated this
    )
}

// check the subspan a hline or vline goes through inside a larger span
#let get-included-span(l-start, l-end, start: 0, end: 0, limit: 0) = {
    if l-start in (none, auto) {
        l-start = 0
    }

    if l-end in (none, auto) {
        l-end = limit
    }

    l-start = calc.max(0, l-start)
    l-end = calc.min(end, limit)

    // ---- ====     or ==== ----
    if l-end < start or l-start > end {
        return none
    }

    // --##==   ;   ==##-- ;  #### ; ... : intersection.
    (calc.max(l-start, start), calc.min(l-end, end))
}

// restrict hlines and vlines to the cells' borders.
// i.e.
//                | (vline)
//                |
// (hline) ----====---      (= and || indicate intersection)
//             |  ||
//             ----   <--- sample cell
#let v-and-hline-spans-for-cell(cell, hlines: (), vlines: (), x-limit: 0, y-limit: 0, grid: ()) = {
    // only draw lines from the parent cell
    if is-tablex-occupied(cell) {
        return (
            hlines: (),
            vlines: ()
        );
    }

    let hlines = hlines
        .filter(h => {
            let y = h.y

            let in-top-or-bottom = y in (cell.y, cell.y + cell.rowspan)

            let hline-hasnt-already-ended = (
                h.end in (auto, none)  // always goes towards the right
                or h.end >= cell.x + cell.colspan  // ends at or after this cell
            )

            (in-top-or-bottom
                and hline-hasnt-already-ended)
        })
        .map(h => {
            // get the intersection between the hline and the cell's x-span.
            let span = get-included-span(h.start, h.end, start: cell.x, end: cell.x + cell.colspan, limit: x-limit)

            if span == none {  // no intersection!
                none
            } else {
                v-or-hline-with-span(h, start: span.at(0), end: span.at(1))
            }
        })
        .filter(x => x != none)

    let vlines = vlines
        .filter(v => {
            let x = v.x

            let at-left-or-right = x in (cell.x, cell.x + cell.colspan)

            let vline-hasnt-already-ended = (
                v.end in (auto, none)  // always goes towards the bottom
                or v.end >= cell.y + cell.rowspan  // ends at or after this cell
            )

            (at-left-or-right
                and vline-hasnt-already-ended)
        })
        .map(v => {
            // get the intersection between the hline and the cell's x-span.
            let span = get-included-span(v.start, v.end, start: cell.y, end: cell.y + cell.rowspan, limit: y-limit)

            if span == none {  // no intersection!
                none
            } else {
                v-or-hline-with-span(v, start: span.at(0), end: span.at(1))
            }
        })
        .filter(x => x != none)

    (
        hlines: hlines,
        vlines: vlines
    )
}

// Are two hlines the same?
// (Check to avoid double drawing)
#let is-same-hline(a, b) = (
    is-tablex-hline(a)
        and is-tablex-hline(b)
        and a.y == b.y
        and a.start == b.start
        and a.end == b.end
        and a.gutter-restrict == b.gutter-restrict
)

#let _largest-stroke-among-lines(lines, stroke-auto: 1pt, styles: none) = (
    calc.max(0pt, ..lines.map(l => stroke-len(l.stroke, stroke-auto: stroke-auto, styles: styles)))
)

#let _largest-stroke-among-hlines-at-y(y, hlines: none, stroke-auto: 1pt, styles: none) = {
    _largest-stroke-among-lines(hlines.filter(h => h.y == y), stroke-auto: stroke-auto, styles: styles)
}

#let _largest-stroke-among-vlines-at-x(x, vlines: none, stroke-auto: 1pt, styles: none) = {
    _largest-stroke-among-lines(vlines.filter(v => v.x == x), stroke-auto: stroke-auto, styles: styles)
}
