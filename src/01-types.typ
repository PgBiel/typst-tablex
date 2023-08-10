// Basic types for tablex.

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

#let occupied(x: 0, y: 0, parent_x: none, parent_y: none) = (
    tablex-dict-type: "occupied",
    x: x,
    y: y,
    parent_x: parent_x,
    parent_y: parent_y
)
