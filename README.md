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
* [Documentation](#documentation)
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

![image](https://user-images.githubusercontent.com/9021226/230810856-045f6c2c-05fb-4827-97de-e7af14df594f.png)

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


## Documentation



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
