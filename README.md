# typst-tablex (BETA)
More powerful and customizable tables in Typst

**NOTE:** There are still several bugs with this library, but most of them shouldn't be noticeable (except for gutter things). *Please open an issue if you find a bug* and I'll get to it as soon as I can.

## Table of Contents

* [Features](#features)
    * [_Almost_ drop-in replacement for `#table`](#almost-drop-in-replacement-for-table)
    * [colspan/rowspan](#colspanrowspan)
    * [Repeat header rows](#repeat-header-rows)
    * [Customize every single line](#customize-every-single-line)
    * [Customize every single cell](#customize-every-single-cell)
* [Reference](#reference)
    * [Basic types and functions](#basic-types-and-functions)
    * [Gridx and Tablex](#gridx-and-tablex)
* [0.1.0 Roadmap](#010-roadmap)

## Features

### _Almost_ drop-in replacement for `#table`

In most cases, you should be able to replace `#table` with `#tablex` and be good to go for a start - it should look _very_ similar (if not identical). Indeed, the syntax is very similar for the basics:

```js
#tablex(
    columns: (auto, 1em, 1fr, 1fr),  // 3 columns
    rows: auto,  // at least 1 row of auto size,
    fill: red,
    align: center + horizon,
    stroke: green,
    [a], [b], [c], [d],
    [e], [f], [g], [h],
    [i], [j], [k], [l]
)
```

![image](https://user-images.githubusercontent.com/9021226/230810678-3d60c0e1-f757-4ee9-a171-44bde0f464f8.png)

You _might_ find issues in certain cases, especially when using _gutter_, which isn't fully implemented right now. However, for the most part, it should work.

### colspan/rowspan

Your cells can now span more than one column and/or row at once, with `colspanx` / `rowspanx`:

```js
#tablex(
    columns: 3,
    colspanx(2)[a], (),  [b],
    [c], rowspanx(2)[d], [ed],
    [f], (),             [g]
)
```

![image](https://user-images.githubusercontent.com/9021226/230810720-fbdfdbe5-8568-42ed-b8a2-5eff332a89d6.png)

Note that the empty parentheses there are just for organization, and are ignored (unless they come before the first cell - more on that later). They're useful to help us keep track of which cell positions are being used up by the spans because, if we try to add an actual cell at these spots, it will just push the others forward, which might seem unexpected.

Use `colspanx(2)(rowspanx(2)[d])` to colspan and rowspan at the same time. Be careful not to attempt to overwrite other cells' spans, as you will get a nasty error.

### Repeat header rows

You can now ensure the first row (or, rather, the rows covered by the first rowspan) in your table repeats across pages. Just use `repeat-header: true` (default is `false`).

Note that you may wish to customize this. Use `repeat-header: 6` to repeat for 6 more pages. Use `repeat-header: (2, 4)` to repeat only on the 2nd and the 4th page (where the 1st page is the one the table starts in). Additionally, use `header-rows: 5` to ensure the first (e.g.) 5 rows are part of the header (by default, this is 1 - more rows will be repeated where necessary if rowspans are used).

Also, note that, by default, the horizontal lines below the header are transported to other pages, which may be an annoyance if you customize lines too much (see below). Use `header-hlines-have-priority: false` to ensure that the first row in each page will dictate the appearance of the horizontal lines above it (and not the header).

**Warning:** This feature is currently _broken_ if you have **pages of different sizes** in your document. This should be improved in a future update, and will depend on changes in typst itself as well.

Example:

```js
#pagebreak()
#v(80%)

#tablex(
    columns: 4,
    align: center + horizon,
    auto-vlines: false,
    repeat-header: true,

    /* --- header --- */
    rowspanx(2)[*Names*], colspanx(2)[*Properties*], (), rowspanx(2)[*Creators*],
    (),                 [*Type*], [*Size*], (),
    /* -------------- */

    [Machine], [Steel], [5 $"cm"^3$], [John p& Kate],
    [Frog], [Animal], [6 $"cm"^3$], [Robert],
    [Frog], [Animal], [6 $"cm"^3$], [Robert],
    [Frog], [Animal], [6 $"cm"^3$], [Robert],
    [Frog], [Animal], [6 $"cm"^3$], [Robert],
    [Frog], [Animal], [6 $"cm"^3$], [Robert],
    [Frog], [Animal], [6 $"cm"^3$], [Robert],
    [Frog], [Animal], [6 $"cm"^3$], [Rodbert],
)
```

![image](https://user-images.githubusercontent.com/9021226/230810751-776a73c4-9c24-46ba-92cd-76292469ab7d.png)


### Customize every single line

Every single line in the table is either a `hlinex` (horizontal) or `vlinex` (vertical) instance. By default, there is one between every column and between every row - unless you specify a custom line for some column or row, in which case the automatic line for it will be removed. To disable this behavior, use `auto-lines: false`, which will remove _all_ automatic lines. You may also remove only automatic horizontal lines with `auto-hlines: false`, and only vertical with `auto-vlines: false`.

**Note:** `gridx` is an alias for `tablex` with `auto-lines: false`.

For your custom lines, write `hlinex()` at any position and it will add a horizontal line below the current cell row (or at the top, if before any cell). You can use `hlinex(start: a, end: b)` to control the cells which that line spans (`a` is the first column number and `b` is the last column number). You can also specify its stroke with `hlinex(stroke: red + 5pt)` for example. To position it at an arbitrary row, use `hlinex(y: 6)` or similar. (Columns and rows are indexed starting from 0.)

Something similar occurs for `vlinex()`, which has `start`, `end` (first row and last row it spans), and also `stroke`. They will, by default, be placed to the right of the current cell, and will span the entire table (top to bottom). To override the default placement, use `vlinex(x: 2)` or similar.

**Note:** Only one hline or vline with the same span (same start/end) can be placed at once.

**Note:** You can also place vlines before the first cell, in which case _they will be placed consecutively, each after the last `vlinex()`_. That is, if you place several of them in a row (*before the first cell* only), then it will not place all of them at one location (which is what happens if you place them anywhere after the first cell), but rather one after the other. With this behavior, you can specify `()` between each vline to _skip_ certain positions (again, only before the first cell - afterwards, all `()` are ignored).

Here's a sample:

```js
#tablex(
    columns: 4,
    auto-lines: false,
    vlinex(), vlinex(), vlinex(), (), vlinex(),
    colspanx(2)[a], (),  [b], [J],
    [c], rowspanx(2)[d], [e], [K],
    [f], (),             [g], [L],
)

#tablex(
    columns: 4,
    auto-vlines: false,
    colspanx(2)[a], (),  [b], [J],
    [c], rowspanx(2)[d], [e], [K],
    [f], (),             [g], [L],
)

#gridx(
    columns: 4,
    (), (), vlinex(end: 2),
    hlinex(stroke: yellow + 2pt),
    colspanx(2)[a], (),  [b], [J],
    hlinex(start: 0, end: 1, stroke: yellow + 2pt),
    hlinex(start: 1, end: 2, stroke: green + 2pt),
    hlinex(start: 2, end: 3, stroke: red + 2pt),
    hlinex(start: 3, end: 4, stroke: blue.lighten(50%) + 2pt),
    [c], rowspanx(2)[d], [e], [K],
    hlinex(start: 2),
    [f], (),             [g], [L],
)
```

![image](https://user-images.githubusercontent.com/9021226/230817335-8a908d44-77be-45d2-b98f-89e9ccf07dc7.png)

#### Bulk line customization

You can also *bulk-customize lines* by specifying `map-hlines: h => new_hline` and `map-vlines: v => new_vline`. For example:

```
#tablex(
    columns: 3,
    map-hlines: h => (..h, stroke: blue),
    map-vlines: h => (..h, stroke: green + 2pt),
    colspanx(2)[a], (),  [b],
    [c], rowspanx(2)[d], [ed],
    [f], (),             [g]
)
```

![image](https://user-images.githubusercontent.com/9021226/230810904-fde2ee5d-8f9e-4b8b-a981-0df7d3fad93f.png)


### Customize every single cell

Cells can be customized entirely. Instead of specifying content (e.g. \[text\]) as a table item, you can specify `cellx(property: a, property: b)[text]`, which allows you to customize properties, such as:

- `colspan: 2` (same as using `colspan(2, ...)[...]`)
- `rowspan: 3` (same as using `rowspan(3, ...)[...]`)
- `align: center` (override whole-table alignment for this cell)
- `fill: blue` (fill just this cell with that color)
- `inset: 0pt` (override inset for this cell - note that this can look off unless you use auto columns and rows)
- `x: 5` (arbitrarily place the cell at the given column - may error if conflicts occur)
- `y: 6` (arbitrarily place the cell at the given row - may error if conflicts occur)

Additionally, instead of specifying content to the cell, you can specify a function `(column, row) => content`, allowing each cell to be aware of where its positioned. (Note that positions are recorded in the cell's `.x` and `.y` attributes, and start as `auto` unless you specify otherwise.)

For example:

```js
#tablex(
    columns: 3,
    fill: red,
    align: right,
    colspanx(2)[a], (),  [beeee],
    [c], rowspanx(2)[d], cellx(fill: blue, align: left)[e],
    [f], (),             [g]
)
```

![image](https://user-images.githubusercontent.com/9021226/230810948-fbccf096-7e28-4fbe-90f8-ca6a70238a4f.png)


#### Bulk customization of cells

To customize multiple cells at once, you have a few options:

1. `map-cells: cell => cell` (given a cell, returns a new cell). You can use this to customize the cell's attributes, but also  to change its positions (however, avoid doing that as it can easily generate conflicts). You can access the cell's position with `cell.x` and `cell.y`. Use something like `(..cell, fill: blue)` for example to ensure the other properties are kept. (Calling `cellx` here is not necessary. If overriding content, use `content: [whatever]`).

2. `map-rows: (row_index, cells) => cells` (given a row index and all cells in it, return a new array of cells). Allows customizing entire rows, but note that the cells in `cells` can be `none` if they're some position occupied by a colspan or rowspan of another cell. Ensure you return the cells in the order of modification. Also, ensure you do not change the row of any cell here, or it will error. You can change the cells' columns, but that will certainly generate conflicts if any col/rowspans are involved (in general, you cannot change col/rowspans here).

3. `map-cols: (col_index, cells) => cells` (given a column index and all cells in it, return a new array of cells). Similar to `map-rows`, but for customizing columns. You cannot change the column of any cell here. (To do that, `map-cells` is required.)

**Note:** Execution order is `map-cells` => `map-cols` => `map-rows`.

Example:

```js
#tablex(
    columns: 4,
    auto-vlines: true,

    map-cells: cell => {
        (..cell, content: emph(cell.content))
    },

    map-rows: (row, cells) => cells.map(c =>
        if c == none {
            c
        } else {
            (..c, content: [#c.content])
        }
    ),

    map-cols: (col, cells) => cells.map(c =>
        if c == none {
            c
        } else {
            (..c, fill: if col < 2 { blue } else { yellow })
        }
    ),

    colspanx(2)[a], (),  [b], [J],
    [c], rowspanx(2)[dd], [e], [K],
    [f], (),             [g], [L],
)
```

![image](https://user-images.githubusercontent.com/9021226/230810983-32136a1c-35fb-46cc-9935-399e680b4d5b.png)


## Reference

### Basic types and functions

1. `cellx`: Represents a table cell, and is initialized as follows:

    ```js
    #let cellx(content,
        x: auto, y: auto,
        rowspan: 1, colspan: 1,
        fill: auto, align: auto,
        inset: auto
    ) = (
        tablex-dict-type: "cell",
        content: content,
        rowspan: rowspan,
        colspan: colspan,
        align: align,
        fill: fill,
        inset: inset,
        x: x,
        y: y,
    )
    ```
    where:

    - `tablex-dict-type` is the type marker
    - `content` is the cell's content (either `content` or a function with `(col, row) => content`)
    - `rowspan` is how many rows this cell spans (default 1)
    - `colspan` is how many columns this cell spans (default 1)
    - `align` is this cell's align override, such as "center" (default `auto` to follow the rest of the table)
    - `fill` is this cell's fill override, such as "blue" (default `auto` to follow the rest of the table)
    - `inset` is this cell's inset override, such as `5pt` (default `auto` to follow the rest of the table)
    - `x` is the cell's column index (0..len-1) - `auto` indicates it wasn't assigned yet
    - `y` is the cell's row index (0..len-1) - `auto` indicates it wasn't assigned yet

2. `hlinex`: represents a horizontal line:

    ```js
    #let hlinex(start: 0, end: auto, y: auto, stroke: auto, stop-pre-gutter: auto, gutter-restrict: none) = (
        tablex-dict-type: "hline",
        start: start,
        end: end,
        y: y,
        stroke: stroke,
        stop-pre-gutter: stop-pre-gutter,
        gutter-restrict: gutter-restrict,
    )
    ```

    where:

    - `tablex-dict-type` is the type marker
    - `start` is the column index where the hline starts from (default `0`, a.k.a. the beginning)
    - `end` is the last column the hline touches (default `auto`, a.k.a. all the way to the end)
        - Note that hlines will *not* be drawn over cells with `colspan` larger than 1, even if their spans (`start`-`end`) include that cell.
    - `y` is the index of the row at the top of which the hline is drawn. (Defaults to `auto`, a.k.a. depends on where you placed the `hline` among the table items - it's always on the top of the row below the current one.)
    - `stroke` is the hline's stroke override (defaults to `auto`, a.k.a. follow the rest of the table).
    - `stop-pre-gutter`: When `true`, the hline will not be drawn over gutter (which is the default behavior of tables). Defaults to `auto` which is essentially `false` (draw over gutter).
    - `gutter-restrict`: Either `top`, `bottom`, or `none`. Has no effect if `row-gutter` is set to `none`. Otherwise, defines if this `hline` should be drawn only on the top of the row gutter (`top`); on the bottom (`bottom`); or on both the top and the bottom (`none`, the default). Note that `top` and `bottom` are alignment values (not strings).

3. `vlinex`: represents a vertical line:

    ```js
    #let vlinex(start: 0, end: auto, x: auto, stroke: auto, stop-pre-gutter: auto, gutter-restrict: none) = (
        tablex-dict-type: "vline",
        start: start,
        end: end,
        x: x,
        stroke: stroke,
        stop-pre-gutter: stop-pre-gutter,
        gutter-restrict: gutter-restrict,
    )
    ```

    where:

    - `tablex-dict-type` is the type marker
    - `start` is the row index where the vline starts from (default `0`, a.k.a. the top)
    - `end` is the last row the vline touches (default `auto`, a.k.a. all the way to the bottom)
        - Note that vlines will *not* be drawn over cells with `rowspan` larger than 1, even if their spans (`start`-`end`) include that cell.
    - `x` is the index of the column to the left of which the vline is drawn. (Defaults to `auto`, a.k.a. depends on where you placed the `vline` among the table items.)
        - For a `vline` to be placed after all columns, its `x` value will be equal to the amount of columns (which isn't a valid column index, but it's what is used here).
    - `stroke` is the vline's stroke override (defaults to `auto`, a.k.a. follow the rest of the table).
    - `stop-pre-gutter`: When `true`, the vline will not be drawn over gutter (which is the default behavior of tables). Defaults to `auto` which is essentially `false` (draw over gutter).
    - `gutter-restrict`: Either `left`, `right`, or `none`. Has no effect if `column-gutter` is set to `none`. Otherwise, defines if this `vline` should be drawn only to the left of the column gutter (`left`); to the right (`right`); or on both the left and the right (`none`, the default). Note that `left` and `right` are alignment values (not strings).

4. The `occupied` type is an internal type used to represent cell positions occupied by cells with `colspan` or `rowspan` greater than 1. 

5. Use `is-tablex-cell`, `is-tablex-hline`, `is-tablex-vline` and `is-tablex-occupied` to check if a particular object has the corresponding type marker.

6. `colspanx` and `rowspanx` are shorthands for setting the `colspan` and `rowspan` attributes of `cellx`. They can also be nested (one given as an argument to the other) to combine their properties (e.g., `colspanx(2)(rowspanx(3)[a])`). They accept all other cell properties with named arguments. For example, `colspanx(2, align: center)[b]` is equivalent to `cellx(colspan: 2, align: center)[b]`.

### Gridx and Tablex

1. `gridx` is equivalent to `tablex` with `auto-lines: false`; see below.

2. `tablex:` The main function for creating a table with this library:

    ```js
    #let tablex(
        columns: auto, rows: auto,
        inset: 5pt,
        align: auto,
        fill: none,
        stroke: auto,
        column-gutter: auto, row-gutter: auto,
        gutter: none,
        repeat-header: false,
        header-rows: 1,
        header-hlines-have-priority: true,
        auto-lines: true,
        auto-hlines: auto,
        auto-vlines: auto,
        map-cells: none,
        map-hlines: none,
        map-vlines: none,
        map-rows: none,
        map-cols: none,
        ..items
    ) = {
    // ...
    }
    ```

    **Parameters:**

    - `columns`: The sizes of each column. They work just like regular `table`'s columns, and can be:
        - an array of lengths (`1pt`, `2em`, `100%`, ...), including fractional (`2fr`), to specify the width of each column
            - `auto` may be specified to automatically resize the column based on the space available
            - when specifying fractional columns, the available space is divided between them, weighted on the fraction value of each column
                - For example, with `(1fr, 2fr)`, the available space will be divided by 3 (1 + 2), and the first column will have 1/3 of the space, while the second will have 2/3.
        - a single length like above, to indicate the width of a single column (equivalent to just placing it inside a unit array)
        - an integer (such as `4`), as a shorthand for `(auto,) * 4` (that many `auto` columns)
    - `rows`: The sizes of each row. They follow the exact same format as `columns`, except that the "available space" is infinite.
        - *Note:* support for fractional sizes for rows is still rudimentary - they only work properly on the table's first page; on the second page and onwards, they will not behave properly, differently from the default `#table`.
    - `inset`: Inset/internal padding to give to each cell. Defaults to `5pt` (the `#table` default).
    -  `fill`: Color with which to fill cells' backgrounds. Defaults to `none`, or no fill. Must be either a `color`, such as `blue`, or a function `(column, row) => color` (to customize for each individual cell).

    - `stroke`: Indicates how to draw the table lines. Defaults to the current line styles in the document. For example: `5pt + red` to change the color and the thickness.
 
    - `column-gutter`: optional separation (length) between columns (such as `5pt`). Defaults to `none` (disable). At the moment, looks a bit ugly if your table has a `hline` attempting to cross a `colspan`.

    - `row-gutter`: optional separation (length) between rows. Defaults to `none` (disable). At the moment, looks a bit ugly if your table has a `vline` attempting to cross a `rowspan`.

    - `gutter`: Sets a length to both `column-` and `row-gutter` at the same time (overridable by each).

    - `repeat-header`: Controls header repetition. If set to `true`, the first row (or the amount of rows specified in `header-rows`), including its rowspans, is repeated across all pages this table spans. If set to `false` (default), the aforementioned header row is not repeated in any page. If set to an integer (such as `4`), repeats for that many pages after the first, then stops. If set to an array of integers (such as `(3, 4)`), repeats only on those pages _relative to the table's first page_ (page 1 here is where the table is, so adding `1` to said array has no effect).

        - **Warning:** This currently does not work properly if your document has pages of different sizes.

    - `header-rows`: minimum amount of rows for the repeatable
    header. 1 by default. Automatically increases if
    one of the cells is a rowspan that would go beyond the
    given amount of rows. For example, if 3 is given,
    then at least the first 3 rows will repeat.

    - `header-hlines-have-priority`: if `true`, the horizontal
    lines below the header being repeated take priority
    over the rows they appear atop of on further pages.
    If `false`, they draw their own horizontal lines.
    Defaults to `true`.
        - For example, if your header has a blue hline under it, that blue hline will display on all pages it is repeated on if this option is `true`. If this option is `false`, the header will repeat, but the blue hline will not.

    - `auto-lines`: Shorthand to apply a boolean to both `auto-hlines` and `auto-vlines` at the same time (overridable by each). Defaults to `true`.

    - `auto-hlines`: If `true`, draw a horizontal line on every line where you did not manually draw one; if `false`, no hlines other than the ones you specify (via `hlinex`) are drawn. Defaults to `auto` (follows `auto-lines`, which in turn defaults to `true`).

    - `auto-vlines`: If `true`, draw a vertical line on every line where you did not manually draw one; if `false`, no vlines other than the ones you specify (via `vlinex`) are drawn. Defaults to `auto` (follows `auto-lines`, which in turn defaults to `true`).

    - `map-cells`: A function which takes a single `cellx` and returns another `cellx`, or a `content` which is converted to `cellx` by `cellx[#content]`. You can customize the cell in pretty much any way using this function; just take care to avoid conflicting with already-placed cells if you move it.

    - `map-hlines`: A function which takes each horizontal line object (`hlinex`) and returns another, optionally modifying its properties. You may also change its row position (`y`). Note that this is also applied to lines generated by `auto-hlines`.

    - `map-vlines`: A function which takes each horizontal line object (`vlinex`) and returns another, optionally modifying its properties. You may also change its column position (`x`). Note that this is also applied to lines generated by `auto-vlines`.

    - `map-rows`: A function mapping each row of cells to new values or modified properties.
    Takes `(row_num, cell_array)` and returns
    the modified `cell_array`. Note that, with your function, they
    cannot be sent to another row. Also, please preserve the order of the cells. This is especially important given that cells may be `none` if they're actually a position taken by another cell with colspan/rowspan. Make sure the `none` values are in the same indexes when the array is returned.

    - `map-cols`: A function mapping each column of cells to new values or modified properties.
    Takes `(col_num, cell_array)` and returns
    the modified `cell_array`. Note that, with your function, they
    cannot be sent to another column. Also, please preserve the order of the cells. This is especially important given that cells may be `none` if they're actually a position taken by another cell with colspan/rowspan. Make sure the `none` values are in the same indexes when the array is returned.

## 0.1.0 Roadmap

- [ ] General
    - [ ] More docs
    - [ ] Code cleanup
- [ ] `#table` parity
    - [X] `columns:`, `rows:`
        - [X] Basic support
        - [X] Accept a single size to mean a single column
        - [X] Adjust `auto` columns and rows
        - [X] Accept integers to mean multiple `auto`
        - [X] Basic unit conversion (em -> pt, etc.)
        - [X] Ratio unit conversion (100% -> page width...)
        - [X] Fractional unit conversion based on available space (1fr, 2fr -> 1/3, 2/3)
        - [X] Shrink `auto` columns based on available space
    - [X] `fill`
        - [X] Basic support (`color` for general fill)
        - [X] Accept a function (`(row, column) => color`)
    - [X] `align`
        - [X] Basic support (`alignment` and `2d alignment` apply to all cells)
        - [X] Accept a function (`(row, column) => alignment/2d alignment`)
    - [X] `inset`
    - [ ] `gutter`
        - [X] Basic support
            - [X] `column-gutter`
            - [X] `row-gutter`
        - [ ] Hline, vline adaptations
            - [X] `stop-pre-gutter`: Makes the hline/vline not transpose gutter boundaries
            - [X] `gutter-restrict`: Makes the hline/vline not draw on both sides of a gutter boundary, and instead pick one (top/bottom; left/right)
            - [ ] Properly work with gutters after colspanxs/rowspanxs
    - [X] `stroke`
        - [X] Basic support (change all lines, vline or hline, without override)
        - [X] `none` for no stroke
    - [X] Default to lines on every row and column
- [ ] New features for `#tablex`
    - [X] Basic types (`cellx`, `hlinex`, `vlinex`)
    - [X] `hlinex`, `vlinex`
        - [X] Auto-positioning when placed among cells
        - [X] Arbitrary positioning
        - [X] Allow customizing `stroke`
    - [X] `colspanx`, `rowspanx`
        - [X] Interrupt `hlinex` and `vlinex` with `end: auto`
        - [X] Support simultaneous col/rowspan with `cellx(colspanx:, rowspanx:)`
        - [X] Support nesting colspan/rowspan (`colspanx(rowspanx())`)
        - [X] Support cell attributes (e.g. `colspanx(2, align: left)[a]`)
        - [X] Reliably detect conflicts
    - [ ] Repeating headers
        - [X] Basic support (first row group repeats on every page)
        - [ ] Work with different page sizes
        - [X] `repeat-header`: Control header repetition
            - [X] `true`: Repeat on all pages
            - [X] integer: Repeat for the next 'n' pages
            - [X] array of integers: Repeat on those (relative) pages
            - [X] `false` (default): Do not repeat
        - [X] `header-rows`: Indicate what to consider as a "header"
            - [X] integer: At least first 'n' rows are a header (plus whatever rowspanxs show up there)
                - [X] Defaults to 1
            - [X] `none` or `0`: no header (disables header repetition regardless of `repeat-header`)
    - [X] `cellx`
        - [X] Auto-positioning based on order and columns
        - [X] Place empty cells when there are too many
        - [X] Allow arbitrary positioning with `cellx(x:, y:)`
        - [X] Allow `align` override
        - [X] Allow `fill` override
        - [X] Allow `inset` override
            - [X] Works properly only with `auto` cols/rows
        - [X] Dynamic content (maybe shortcut for `map-cells` on a single cell)
    - [X] Auto-lines
        - [X] `auto-hlines` - `true` to place on all lines without hlines, `false` otherwise
        - [X] `auto-vlines` - similar
        - [X] `auto-lines` - controls both simultaneously (defaults to `true`)
    - [X] Iteration attributes
        - [X] `map-cells` - Customize every single cell
        - [X] `map-hlines` - Customize each horizontal line
        - [X] `map-vlines` - Customize each vertical line
        - [X] `map-rows` - Customize entire rows of cells
        - [X] `map-cols` - Customize entire columns of cells
