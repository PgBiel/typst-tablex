// -- tablex imports --
#import "0-common.typ": *
#import "1-types.typ": *
#import "2-type-validators.typ": *
#import "3-utilities.typ": *
#import "4-grid.typ": *
#import "5-col-row-size.typ": *
#import "6-width-height.typ": *
// -- end imports --

#let parse-stroke(stroke) = {
    if type(stroke) == "color" {
        stroke + 1pt
    } else if type(stroke) in ("length", "relative length", "ratio", "stroke", "dictionary") or stroke in (none, auto) {
        stroke
    } else {
        panic("Invalid stroke '" + repr(stroke) + "'.")
    }
}

// How much should this line expand?
// If it's not at the edge of the parent line => don't expand
// spanned-tracks-len: row_len (if vline), col_len (if hline)
#let get-actual-expansion(line, spanned-tracks-len: 0) = {
    // TODO: better handle negative expansion
    if line.expand in (none, (none, none), auto, (auto, auto)) {
        return (none, none)
    }
    if type(line.expand) != "array" {
        line.expand = (line.expand, line.expand)
    }

    let parent = get-top-parent(line)
    let parent-start = default-if-auto-or-none(parent.start, 0)
    let parent-end = default-if-auto-or-none(parent.end, spanned-tracks-len)

    let start = default-if-auto-or-none(line.start, 0)
    let end = default-if-auto-or-none(line.end, spanned-tracks-len)

    let expansion = (none, none)

    if start == parent-start {  // starts where its parent starts
        expansion.at(0) = default-if-auto(line.expand.at(0), 0pt)  // => expand to the left
    }

    if end == parent-end {  // ends where its parent ends
        expansion.at(1) = default-if-auto(line.expand.at(1), 0pt)  // => expand to the right
    }

    expansion
}

#let draw-hline(hline, initial_x: 0, initial_y: 0, columns: (), rows: (), stroke: auto, vlines: (), gutter: none, pre-gutter: false) = {
    let start = hline.start
    let end = hline.end
    let stroke-auto = parse-stroke(stroke)
    let stroke = default-if-auto(hline.stroke, stroke)
    let stroke = parse-stroke(stroke)

    if default-if-auto-or-none(start, 0) == default-if-auto-or-none(end, columns.len()) { return }

    if gutter != none and gutter.row != none and ((pre-gutter and hline.gutter-restrict == bottom) or (not pre-gutter and hline.gutter-restrict == top)) {
        return
    }

    let expand = get-actual-expansion(hline, spanned-tracks-len: columns.len())
    let left-expand = default-if-auto-or-none(expand.at(0), 0pt)
    let right-expand = default-if-auto-or-none(expand.at(1), 0pt)

    if default-if-auto(hline.stroke-expand, true) == true {
        let largest-stroke = _largest-stroke-among-vlines-at-x.with(vlines: vlines, stroke-auto: stroke-auto)
        left-expand += largest-stroke(default-if-auto-or-none(start, 0)) / 2  // expand to the left to close stroke gap
        right-expand += largest-stroke(default-if-auto-or-none(end, columns.len())) / 2  // close stroke gap to the right
    }

    let y = height-between(start: initial_y, end: hline.y, rows: rows, gutter: gutter, pre-gutter: pre-gutter)
    let start_x = width-between(start: initial_x, end: start, columns: columns, gutter: gutter, pre-gutter: false) - left-expand
    let end_x = width-between(start: initial_x, end: end, columns: columns, gutter: gutter, pre-gutter: hline.stop-pre-gutter == true) + right-expand

    if end_x - start_x < 0pt {
        return  // negative length
    }

    let start = (
        start_x,
        y
    )
    let end = (
        end_x,
        y
    )

    if stroke != auto {
        if stroke != none {
            line(start: start, end: end, stroke: stroke)
        }
    } else {
        line(start: start, end: end)
    }
}

#let draw-vline(vline, initial_x: 0, initial_y: 0, columns: (), rows: (), stroke: auto, gutter: none, hlines: (), pre-gutter: false, stop-before-row-gutter: false) = {
    let start = vline.start
    let end = vline.end
    let stroke-auto = parse-stroke(stroke)
    let stroke = default-if-auto(vline.stroke, stroke)
    let stroke = parse-stroke(stroke)

    if default-if-auto-or-none(start, 0) == default-if-auto-or-none(end, rows.len()) { return }

    if gutter != none and gutter.col != none and ((pre-gutter and vline.gutter-restrict == right) or (not pre-gutter and vline.gutter-restrict == left)) {
        return
    }

    let expand = get-actual-expansion(vline, spanned-tracks-len: rows.len())
    let top-expand = default-if-auto-or-none(expand.at(0), 0pt)
    let bottom-expand = default-if-auto-or-none(expand.at(1), 0pt)

    if default-if-auto(vline.stroke-expand, true) == true {
        let largest-stroke = _largest-stroke-among-hlines-at-y.with(hlines: hlines, stroke-auto: stroke-auto)
        top-expand += largest-stroke(default-if-auto-or-none(start, 0)) / 2  // close stroke gap to the top
        bottom-expand += largest-stroke(default-if-auto-or-none(end, rows.len())) / 2  // close stroke gap to the bottom
    }

    let x = width-between(start: initial_x, end: vline.x, columns: columns, gutter: gutter, pre-gutter: pre-gutter)
    let start_y = height-between(start: initial_y, end: start, rows: rows, gutter: gutter) - top-expand
    let end_y = height-between(start: initial_y, end: end, rows: rows, gutter: gutter, pre-gutter: stop-before-row-gutter or vline.stop-pre-gutter == true) + bottom-expand

    if end_y - start_y < 0pt {
        return  // negative length
    }

    let start = (
        x,
        start_y
    )
    let end = (
        x,
        end_y
    )

    if stroke != auto {
        if stroke != none {
            line(start: start, end: end, stroke: stroke)
        }
    } else {
        line(start: start, end: end)
    }
}
