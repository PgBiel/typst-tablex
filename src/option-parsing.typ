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
                    if type(e) not in (_length-type, _rel_len-type, _ratio-type) {
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

    if type(col-gutter) in (_length-type, _rel_len-type, _ratio-type) {
        col-gutter = convert-length-to-pt(col-gutter, styles: styles, page-size: page-width)
    }

    if type(row-gutter) in (_length-type, _rel_len-type, _ratio-type) {
        row-gutter = convert-length-to-pt(row-gutter, styles: styles, page-size: page-width)
    }

    (col: col-gutter, row: row-gutter)
}

// Accepts a map-X param, and returns its default, or validates
// it.
#let parse-map-func(map-func, uses-second-param: false) = {
    if map-func in (none, auto) {
        if uses-second-param {
            (a, b) => b  // identity
        } else {
            o => o  // identity
        }
    } else if type(map-func) != _function-type {
        panic("Map parameters must be functions.")
    } else {
        map-func
    }
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
    vlines = vlines.map(map-vlines)
    if vlines.any(h => not is-tablex-vline(h)) {
        panic("'map-vlines' function returned a non-vline.")
    }

    hlines = hlines.map(map-hlines)
    if hlines.any(h => not is-tablex-hline(h)) {
        panic("'map-hlines' function returned a non-hline.")
    }

    let col-len = grid.width
    let row-len = grid-count-rows(grid)

    for row in range(row-len) {
        let original_cells = grid-get-row(grid, row)

        // occupied cells = none for the outer user
        let cells = map-rows(row, original_cells.map(c => {
            if is-tablex-occupied(c) { none } else { c }
        }))

        if type(cells) != _array-type {
            panic("Tablex error: 'map-rows' returned something that isn't an array.")
        }

        // only modify non-occupied cells
        let cells = enumerate(cells).filter(i_c => is-tablex-cell(original_cells.at(i_c.at(0))))

        if cells.any(i_c => not is-tablex-cell(i_c.at(1))) {
            panic("Tablex error: 'map-rows' returned a non-cell.")
        }

        if cells.any(i_c => {
            let c = i_c.at(1)
            let x = c.x
            let y = c.y
            type(x) != _int-type or type(y) != _int-type or x < 0 or y < 0 or x >= col-len or y >= row-len
        }) {
            panic("Tablex error: 'map-rows' returned a cell with invalid coordinates.")
        }

        if cells.any(i_c => i_c.at(1).y != row) {
            panic("Tablex error: 'map-rows' returned a cell in a different row (the 'y' must be kept the same).")
        }

        if cells.any(i_c => {
            let i = i_c.at(0)
            let c = i_c.at(1)
            let orig_c = original_cells.at(i)

            c.colspan != orig_c.colspan or c.rowspan != orig_c.rowspan
        }) {
            panic("Tablex error: Please do not change the colspan or rowspan of a cell in 'map-rows'.")
        }

        for i_cell in cells {
            let cell = i_cell.at(1)
            grid.items.at(grid-index-at(cell.x, cell.y, grid: grid)) = cell
        }
    }

    for column in range(col-len) {
        let original_cells = grid-get-column(grid, column)

        // occupied cells = none for the outer user
        let cells = map-cols(column, original_cells.map(c => {
            if is-tablex-occupied(c) { none } else { c }
        }))

        if type(cells) != _array-type {
            panic("Tablex error: 'map-cols' returned something that isn't an array.")
        }

        // only modify non-occupied cells
        let cells = enumerate(cells).filter(i_c => is-tablex-cell(original_cells.at(i_c.at(0))))

        if cells.any(i_c => not is-tablex-cell(i_c.at(1))) {
            panic("Tablex error: 'map-cols' returned a non-cell.")
        }

        if cells.any(i_c => {
            let c = i_c.at(1)
            let x = c.x
            let y = c.y
            type(x) != _int-type or type(y) != _int-type or x < 0 or y < 0 or x >= col-len or y >= row-len
        }) {
            panic("Tablex error: 'map-cols' returned a cell with invalid coordinates.")
        }

        if cells.any(i_c => i_c.at(1).x != column) {
            panic("Tablex error: 'map-cols' returned a cell in a different column (the 'x' must be kept the same).")
        }

        if cells.any(i_c => {
            let i = i_c.at(0)
            let c = i_c.at(1)
            let orig_c = original_cells.at(i)

            c.colspan != orig_c.colspan or c.rowspan != orig_c.rowspan
        }) {
            panic("Tablex error: Please do not change the colspan or rowspan of a cell in 'map-cols'.")
        }

        for i_cell in cells {
            let cell = i_cell.at(1)
            cell.content = [#cell.content]
            grid.items.at(grid-index-at(cell.x, cell.y, grid: grid)) = cell
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
