// #09
// Parsers and validators of tablex options.

// -- tablex imports --
#import "common.typ": *
#import "types.typ": *
#import "type-validators.typ": *
#import "utilities.typ": *
#import "grid.typ": *
#import "col-row-size.typ": *
#import "width-height.typ": *
// -- end imports --

#let _parse-lines(
    hlines, vlines,
    page-width: none, page-height: none,
    styles: none
) = {
    let parse-func(line, page-size: none) = {
        line.stroke-expand = line.stroke-expand == true
        line.expand = default-if-auto(line.expand, none)
        if type(line.expand) != _array-type and line.expand != none {
            line.expand = (line.expand, line.expand)
        }
        line.expand = if line.expand == none {
            none
        } else {
            line.expand.slice(0, 2).map(e => {
                if e == none {
                    e
                } else {
                    e = default-if-auto(e, 0pt)
                    if type(e) not in (_length-type, _rel-len-type, _ratio-type) {
                        panic("'expand' argument to lines must be a pair (length, length).")
                    }

                    convert-length-to-pt(e, styles: styles, page-size: page-size)
                }
            })
        }

        line
    }
    (
        hlines: hlines.map(parse-func.with(page-size: page-width)),
        vlines: vlines.map(parse-func.with(page-size: page-height))
    )
}

// Parses 'auto-lines', generating the corresponding lists of
// new hlines and vlines
#let generate-autolines(auto-lines: false, auto-hlines: auto, auto-vlines: auto, hlines: none, vlines: none, col-len: none, row-len: none) = {
    let auto-hlines = default-if-auto(auto-hlines, auto-lines)
    let auto-vlines = default-if-auto(auto-vlines, auto-lines)

    let new-hlines = ()
    let new-vlines = ()

    if auto-hlines {
        new-hlines = range(0, row-len + 1)
            .filter(y => hlines.filter(h => h.y == y).len() == 0)
            .map(y => hlinex(y: y))
    }

    if auto-vlines {
        new-vlines = range(0, col-len + 1)
            .filter(x => vlines.filter(v => v.x == x).len() == 0)
            .map(x => vlinex(x: x))
    }

    (new-hlines: new-hlines, new-vlines: new-vlines)
}

#let parse-gutters(col-gutter: auto, row-gutter: auto, gutter: auto, styles: none, page-width: 0pt, page-height: 0pt) = {
    col-gutter = default-if-auto(col-gutter, gutter)
    row-gutter = default-if-auto(row-gutter, gutter)

    col-gutter = default-if-auto(col-gutter, 0pt)
    row-gutter = default-if-auto(row-gutter, 0pt)

    if type(col-gutter) in (_length-type, _rel-len-type, _ratio-type) {
        col-gutter = convert-length-to-pt(col-gutter, styles: styles, page-size: page-width)
    }

    if type(row-gutter) in (_length-type, _rel-len-type, _ratio-type) {
        row-gutter = convert-length-to-pt(row-gutter, styles: styles, page-size: page-width)
    }

    (col: col-gutter, row: row-gutter)
}

// Accepts a map-X param, and verifies whether it's a function or none/auto.
#let validate-map-func(map-func) = {
    if map-func not in (none, auto) and type(map-func) != _function-type {
        panic("Tablex error: Map parameters, if specified (not 'none'), must be functions.")
    }

    map-func
}

#let apply-maps(
    grid: (),
    hlines: (),
    vlines: (),
    map-hlines: none,
    map-vlines: none,
    map-rows: none,
    map-cols: none,
) = {
    if type(map-vlines) == _function-type {
        vlines = vlines.map(vline => {
            let vline = map-vlines(vline)
            if not is-tablex-vline(vline) {
                panic("'map-vlines' function returned a non-vline.")
            }
            vline
        })
    }

    if type(map-hlines) == _function-type {
        hlines = hlines.map(hline => {
            let hline = map-hlines(hline)
            if not is-tablex-hline(hline) {
                panic("'map-hlines' function returned a non-hline.")
            }
            hline
        })
    }

    let should-map-rows = type(map-rows) == _function-type
    let should-map-cols = type(map-cols) == _function-type

    if not should-map-rows and not should-map-cols {
        return (grid: grid, hlines: hlines, vlines: vlines)
    }

    let col-len = grid.width
    let row-len = grid-count-rows(grid)

    if should-map-rows {
        for row in range(row-len) {
            let original-cells = grid-get-row(grid, row)

            // occupied cells = none for the outer user
            let cells = map-rows(row, original-cells.map(c => {
                if is-tablex-occupied(c) { none } else { c }
            }))

            if type(cells) != _array-type {
                panic("Tablex error: 'map-rows' returned something that isn't an array.")
            }

            if cells.len() != original-cells.len() {
                panic("Tablex error: 'map-rows' returned " + str(cells.len()) + " cells, when it should have returned exactly " + str(original-cells.len()) + ".")
            }

            for (i, cell) in cells.enumerate() {
                let orig-cell = original-cells.at(i)
                if not is-tablex-cell(orig-cell) {
                    // only modify non-occupied cells
                    continue
                }

                if not is-tablex-cell(cell) {
                    panic("Tablex error: 'map-rows' returned a non-cell.")
                }

                let x = cell.x
                let y = cell.y

                if type(x) != _int-type or type(y) != _int-type or x < 0 or y < 0 or x >= col-len or y >= row-len {
                    panic("Tablex error: 'map-rows' returned a cell with invalid coordinates.")
                }
                if y != row {
                    panic("Tablex error: 'map-rows' returned a cell in a different row (the 'y' must be kept the same).")
                }
                if cell.colspan != orig-cell.colspan or cell.rowspan != orig-cell.rowspan {
                    panic("Tablex error: Please do not change the colspan or rowspan of a cell in 'map-rows'.")
                }

                cell.content = [#cell.content]
                grid.items.at(grid-index-at(cell.x, cell.y, grid: grid)) = cell
            }
        }
    }

    if should-map-cols {
        for column in range(col-len) {
            let original-cells = grid-get-column(grid, column)

            // occupied cells = none for the outer user
            let cells = map-cols(column, original-cells.map(c => {
                if is-tablex-occupied(c) { none } else { c }
            }))

            if type(cells) != _array-type {
                panic("Tablex error: 'map-cols' returned something that isn't an array.")
            }

            if cells.len() != original-cells.len() {
                panic("Tablex error: 'map-cols' returned " + str(cells.len()) + " cells, when it should have returned exactly " + str(original-cells.len()) + ".")
            }

            for (i, cell) in cells.enumerate() {
                let orig-cell = original-cells.at(i)
                if not is-tablex-cell(orig-cell) {
                    // only modify non-occupied cells
                    continue
                }

                if not is-tablex-cell(cell) {
                    panic("Tablex error: 'map-cols' returned a non-cell.")
                }

                let x = cell.x
                let y = cell.y

                if type(x) != _int-type or type(y) != _int-type or x < 0 or y < 0 or x >= col-len or y >= row-len {
                    panic("Tablex error: 'map-cols' returned a cell with invalid coordinates.")
                }
                if x != column {
                    panic("Tablex error: 'map-cols' returned a cell in a different column (the 'x' must be kept the same).")
                }
                if cell.colspan != orig-cell.colspan or cell.rowspan != orig-cell.rowspan {
                    panic("Tablex error: Please do not change the colspan or rowspan of a cell in 'map-cols'.")
                }

                cell.content = [#cell.content]
                grid.items.at(grid-index-at(cell.x, cell.y, grid: grid)) = cell
            }
        }
    }

    (grid: grid, hlines: hlines, vlines: vlines)
}

#let validate-header-rows(header-rows) = {
    header-rows = default-if-auto(default-if-none(header-rows, 0), 1)

    if type(header-rows) != _int-type or header-rows < 0 {
        panic("Tablex error: 'header-rows' must be a (positive) integer.")
    }

    header-rows
}

#let validate-repeat-header(repeat-header, header-rows: none) = {
    if header-rows == none or header-rows < 0 {
        return false  // cannot repeat an empty header
    }

    repeat-header = default-if-auto(default-if-none(repeat-header, false), false)

    if type(repeat-header) not in (_bool-type, _int-type, _array-type) {
        panic("Tablex error: 'repeat-header' must be a boolean (true - always repeat the header, false - never), an integer (amount of pages for which to repeat the header), or an array of integers (relative pages in which the header should repeat).")
    } else if type(repeat-header) == _array-type and repeat-header.any(i => type(i) != _int-type) {
        panic("Tablex error: 'repeat-header' cannot be an array of anything other than integers!")
    }

    repeat-header
}

#let validate-header-hlines-priority(
    header-hlines-have-priority
) = {
    header-hlines-have-priority = default-if-auto(default-if-none(header-hlines-have-priority, true), true)

    if type(header-hlines-have-priority) != _bool-type {
        panic("Tablex error: 'header-hlines-have-priority' option must be a boolean.")
    }

    header-hlines-have-priority
}

#let validate-renderer(renderer) = {
    assert(renderer in ("old", "cetz"), message: "Tablex error: 'renderer' option must be either \"old\" or \"cetz\".")

    renderer
}

#let validate-renderer-args(renderer-args, renderer: none) = {
    assert(type(renderer-args) == _dict-type, message: "Tablex error: 'renderer-args' option must be a dictionary.")
    if renderer == "old" {
        assert(renderer-args == (:), message: "Tablex error: renderer 'old' does not accept any keys in 'renderer-args'.")
    } else if renderer == "cetz" {
        let valid-args = ("styles", "cell-cetz-names")
        assert("styles" in renderer-args, message: "Tablex error: renderer 'cetz' requires 'styles' in the 'renderer-args'.")
        assert(renderer-args.keys().all(key => key in valid-args), message: "Tablex error: renderer 'cetz' does not accept any keys in 'renderer-args' other than " + valid-args.map(repr).join(", ") + ". Provided keys: " + renderer-args.keys().map(repr).join(", "))
    } else {
        panic("Internal tablex error: Unexpected renderer '" + renderer + "'.")
    }

    renderer-args
}
