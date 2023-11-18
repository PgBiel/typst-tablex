// Generates groups of rows.
// By default, 1 row + rows from its rowspan cells = 1 row group.
// The first row group is the header, which is repeated across pages.
#let generate-row-groups(ctx) = {
    let (
      grid,
      columns,
      rows,
      hlines,
      vlines,
      header-rows
    ) = ctx;
    let col-len = columns.len()
    let row-len = rows.len()

    // specialize some functions for the given grid, columns and rows
    let v-and-hline-spans-for-cell = v-and-hline-spans-for-cell.with(vlines: vlines, x_limit: col-len, y_limit: row-len, grid: grid)

    let this-row-group = (rows: ((),), hlines: (), vlines: (), y-span: (0, 0))

    let total_width = width-between(end: none)

    let row-group-add-counter = 1  // how many more rows are going to be added to the latest row group
    let header-rows-count = calc.min(row-len, header-rows)

    for row in range(0, row-len) {
        for column in range(0, col-len) {
            let cell = grid-at(grid, column, row)
            let lines-dict = v-and-hline-spans-for-cell(cell, hlines: hlines)
            let hlines = lines-dict.hlines
            let vlines = lines-dict.vlines

            if is-tablex-cell(cell) {
                // ensure row-spanned rows are in the same group
                row-group-add-counter = calc.max(row-group-add-counter, cell.rowspan)

                this-row-group.rows.last().push(cell)

                let hlines = hlines
                    .filter(h =>
                        this-row-group.hlines
                            .filter(is-same-hline.with(h))
                            .len() == 0)

                let vlines = vlines
                    .filter(v => v not in this-row-group.vlines)

                this-row-group.hlines += hlines
                this-row-group.vlines += vlines
            }
        }

        row-group-add-counter = calc.max(0, row-group-add-counter - 1)  // one row added
        header-rows-count = calc.max(0, header-rows-count - 1)  // ensure at least the amount of requested header rows was added

        // added all pertaining rows to the group
        // now we can draw it
        if row-group-add-counter <= 0 and header-rows-count <= 0 {
            row-group-add-counter = 1

            let row-group = this-row-group

            // get where the row starts and where it ends
            let start-y = row-group.y-span.at(0)
            let end-y = row-group.y-span.at(1)

            let next-y = end-y + 1

            // return this row group
            (this-row-group,)

            this-row-group = (rows: ((),), hlines: (), vlines: (), y-span: (next-y, next-y))
        } else {
            this-row-group.rows.push(())
            this-row-group.y-span.at(1) += 1
        }
    }
}
