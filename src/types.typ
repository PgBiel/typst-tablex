// #01
// Basic types for tablex.

// A horizontal line.
#let hlinex(
    start: 0, end: auto, y: auto,
    stroke: auto,
    stop-pre-gutter: auto, gutter-restrict: none,
    stroke-expand: true,
    expand: none
) = (
    tablex-dict-type: "hline",
    start: start,
    end: end,
    y: y,
    stroke: stroke,
    stop-pre-gutter: stop-pre-gutter,
    gutter-restrict: gutter-restrict,
    stroke-expand: stroke-expand,
    expand: expand,
    parent: none,  // if hline was broken into multiple
)

// A vertical line.
#let vlinex(
    start: 0, end: auto, x: auto,
    stroke: auto,
    stop-pre-gutter: auto, gutter-restrict: none,
    stroke-expand: true,
    expand: none
) = (
    tablex-dict-type: "vline",
    start: start,
    end: end,
    x: x,
    stroke: stroke,
    stop-pre-gutter: stop-pre-gutter,
    gutter-restrict: gutter-restrict,
    stroke-expand: stroke-expand,
    expand: expand,
    parent: none,
)

// Holds data for a single tablex cell.
// render: options passed to the renderer during rendering stage
#let cellx(
    content,
    x: auto, y: auto,
    rowspan: 1, colspan: 1,
    fill: auto, align: auto,
    inset: auto,
    fit-spans: auto,
    render: none,
) = (
    tablex-dict-type: "cell",
    content: content,
    rowspan: rowspan,
    colspan: colspan,
    align: align,
    fill: fill,
    inset: inset,
    fit-spans: fit-spans,
    render: render,
    x: x,
    y: y,
)

// A cell which was merged with another one.
// Indicates its position in the grid is occupied by its parent cell.
#let occupied(x: 0, y: 0, parent-x: none, parent-y: none) = (
    tablex-dict-type: "occupied",
    x: x,
    y: y,
    parent-x: parent-x,
    parent-y: parent-y
)
