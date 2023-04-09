#import "tablex.typ": *

*Test*

test

deeteeeeereeeedetteeeee
#tablex(
    columns: (auto, auto, auto), // rows: ((1em, 1em, 1em),) eeee
    rows: (auto,),
    column-gutter: 1fr,
    row-gutter: none,
    repeat-header: (3, 4),
    align: (column, row) => {(top, center).at(calc.mod(row + column, 2))},
    // fill: (column, row) => {(blue, red).at(calc.mod(row + column, 2))},
    vline(), vline(), vline(), vline(),
    hline(),
    [*My*], colspan(2)[*Headedr*],  //
    hline(start: 0, end: 1),
    cellx(colspan: 2, rowspan: 2)[a], [b\ c],
    hline(),
    () , (), [cefdsrdeefffeereeeeedeeeeeeerd],
    hline(),
    [a], [b], [xyz],
    hline(end: 1),
    [b],
    hline(),
    ..range(0, 125).map(i => ([d], [#{i + 3}], [a],
    hline())).flatten(),
    [b], [c],
)

#tablex(
    columns: 5,
    rows: 1,
    stroke: red + 2pt,
    vline(), (), vline(), vline(), vline(), vline(),
    hline(),
    [abcdef], colspan(3, rowspan(2, [ee], fill: red), align: horizon), (), (), [c],
    hline(stroke: blue),
    [abcdef], (), (), (), [c],
    hline(),
    [aa], [b], [c], [b], cellx(inset: 2pt, align: center+horizon)[cdeecfeeeeeeeeeeeeeeeeeerdteeettetteeefdxeeeeeddeeeetec],
    hline(),
    // [abcdef], [a], [b],
    // hline(),
)

#tablex(
    columns: 4,
    [a], [b], [c], [d],
    hline(),
    [a], colspan(2, rowspan(2)[b]), [d],
    [a], (), (), [d],
    [a], [b], [c], [d],
)

#tablex(
    columns: (1fr, 1fr, 1fr, 1fr),
    map-cells: cell => (..cell, content: cell.content + [adf]),
    map-rows: (row, cells) => cells.map(c => if c == none { none } else { (..c, content: c.content + [#row]) }),
    map-cols: (col, cells) => cells.map(c => if c == none { none } else { (..c, content: c.content + [#col]) }),
    map-hlines: h => (..h, stroke: 5pt + (red, blue).at(calc.mod(h.y, 2))),
    map-vlines: v => (..v, stroke: 5pt + (yellow, green.darken(50%)).at(calc.mod(v.x, 2))),
    [a], [b], [c], [d],
    hline(),
    [a], colspan(2, rowspan(2)[b]), [d],
    [a], (), (), [d],
    [a], [b], [c], [de],
)

#tablex(
    columns: (1em, 2em, auto, auto),
    rows: (1em, 1em, auto),
    [a], [b], [cd], [d],
    hline(),
    [a], colspan(2, rowspan(2)[bcccccccc\ c\ c\ c]), [d],
    [a], (), (), [d],
    [a], (x, y) => text(size: 7pt, [#(x, y)]), [f], [dee],
    [a], [b], [c], [dee],
)

eeeedreetetdeederfttddeerreeteeeeeerettededteeedeceesdeedeeefteetdedeeesefdferreeedeefgederdaeeteeeeddrdfeeedeeffteeeeeeeeesedteteestderedeeeeefeeeeessdeeee

s

#tablex(
    columns: (1em, 2em, auto, auto),
    rows: (1em, 1em, auto),
    gutter: 20pt,
    auto-lines: true,
    map-hlines: h => (..h, stop-pre-gutter: default-if-auto(h.stop-pre-gutter, true)),
    map-vlines: h => (..h, stop-pre-gutter: default-if-auto(h.stop-pre-gutter, true)),
    [a], [b], [cd], [d],
    hline(start: 0, end: 1),
    hline(start: 4, end: 3),
    hline(start: 1, end: none, gutter-restrict: top),
    hline(start: 1, end: 2, stop-pre-gutter: false, gutter-restrict: bottom), hline(start: 2, end: 4, stop-pre-gutter: true, gutter-restrict: bottom),
    [a],
    vline(gutter-restrict: left),
    vline(start: 0, end: 1, gutter-restrict: right),
    vline(start: 3, end: 4, gutter-restrict: right),
    vline(start: 4, end: 5, gutter-restrict: right),
    vline(stop-pre-gutter: false, start: 1, end: 2, gutter-restrict: right),
    vline(stop-pre-gutter: true, start: 2, end: 3, gutter-restrict: right),
    colspan(2, rowspan(2)[bcccccccc\ c\ c\ c]), [d],
    [a], (), (), [d],
    [a], (x, y) => text(size: 7pt, [#(x, y)]), [f], [dee],
    [a], [b], [c], [dee],
)
