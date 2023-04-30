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
    header-hlines-have-priority: false,
    align: (column, row) => {(top, center).at(calc.mod(row + column, 2))},
    // fill: (column, row) => {(blue, red).at(calc.mod(row + column, 2))},
    vlinex(), vlinex(), vlinex(), vlinex(),
    hlinex(),
    [*My*], colspanx(2)[*Headedr*],  //
    hlinex(start: 0, end: 1),
    cellx(colspan: 2, rowspan: 2)[a], [b\ c],
    hlinex(),
    () , (), [cefdsrdeefffeerddeeeeeedeeeeeeerd],
    hlinex(),
    [a], [b], [xyz],
    hlinex(end: 1),
    [b],
    hlinex(),
    ..range(0, 125).map(i => ([d], [#{i + 3}], [a],
    hlinex())).flatten(),
    [b], [c],
)

#tablex(
    columns: 5,
    rows: 1,
    stroke: red + 2pt,
    vlinex(), (), vlinex(), vlinex(), vlinex(), vlinex(),
    hlinex(),
    [abcdef], colspanx(3, rowspanx(2, [ee], fill: red), align: horizon), (), (), [c],
    hlinex(stroke: blue),
    [abcdef], (), (), (), [c],
    hlinex(),
    [aa], [b], [c], [b], cellx(inset: 2pt, align: center+horizon)[cdeecfeeeeeeeeeeeeeeeeeerdteeettetteeefdxeeeeeddeeeetec],
    hlinex(),
    // [abcdef], [a], [b],
    // hlinex(),
)

#tablex(
    columns: 4,
    [a], [b], [c], [d],
    hlinex(),
    [a], colspanx(2, rowspanx(2)[b]), [d],
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
    hlinex(),
    [a], colspanx(2, rowspanx(2)[b]), [d],
    [a], (), (), [d],
    [a], [b], [c], [de],
)

#tablex(
    columns: (1em, 2em, auto, auto),
    rows: (1em, 1em, auto),
    [a], [b], [cd], [d],
    hlinex(),
    [a], colspanx(2, rowspanx(2)[bcccccccc\ c\ c\ c]), [d],
    [a], (), (), [d],
    [a], (x, y) => text(size: 7pt, [#(x, y)]), [f], [dee],
    [a], [b], [c], [dee],
)

eeeedreetetdeederfttddeerreddeeeteeeeeerettededteeedeceesdeedeeefteetdedeeesefdferreeedeefeettgederedaeeteeeeddrdfeeedeeffteeeeeeeeesedteteestderedeeeeefeeeeessdeeee

s
s
s
s

s

s

#tablex(
    columns: (1em, 2em, auto, auto),
    rows: (1em, 1em, auto),
    gutter: 20pt,
    align: center + horizon,
    auto-lines: true,
    map-hlines: h => (..h, stop-pre-gutter: default-if-auto(h.stop-pre-gutter, true)),
    map-vlines: h => (..h, stop-pre-gutter: default-if-auto(h.stop-pre-gutter, true)),
    [a], [b], [cd], [d],
    hlinex(start: 0, end: 1),
    hlinex(start: 4, end: 3),
    hlinex(start: 1, end: none, gutter-restrict: top),
    hlinex(start: 1, end: 2, stop-pre-gutter: false, gutter-restrict: bottom), hlinex(start: 2, end: 4, stop-pre-gutter: true, gutter-restrict: bottom),
    [a],
    vlinex(gutter-restrict: left),
    vlinex(start: 0, end: 1, gutter-restrict: right),
    vlinex(start: 3, end: 4, gutter-restrict: right),
    vlinex(start: 4, end: 5, gutter-restrict: right),
    vlinex(stop-pre-gutter: false, start: 1, end: 2, gutter-restrict: right),
    vlinex(stop-pre-gutter: true, start: 2, end: 3, gutter-restrict: right),
    colspanx(2, rowspanx(2)[bcccccccc\ c\ c\ c]), [d],
    [a], (), (), [d],
    [a], (x, y) => text(size: 7pt, [#(x, y)]), [f], [dee],
    [a], [b], [c], [dee],
)

== Examples from the docs

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

#repeat[a]
#place(bottom+right)[b]
#tablex(
    columns: 3,
    colspanx(2)[a], (),  [b],
    [c], rowspanx(2)[d], [ed],
    [f], (),             [g]
)

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

#pagebreak()

#tablex(
    columns: 3,
    map-hlines: h => (..h, stroke: blue),
    map-vlines: v => (..v, stroke: green + 2pt),
    colspanx(2)[a], (),  [b],
    [c], rowspanx(2)[d], [ed],
    [f], (),             [g]
)

#tablex(
    columns: 3,
    fill: red,
    align: right,
    colspanx(2)[a], (),  [beeee],
    [c], rowspanx(2)[d], cellx(fill: blue, align: left)[e],
    [f], (),             [g],

    // place this cell at the first column, seventh row
    cellx(colspan: 3, align: center, x: 0, y: 6)[hi I'm down here]
)

#tablex(
    columns: 4,
    auto-vlines: true,

    // make all cells italicized
    map-cells: cell => {
        (..cell, content: emph(cell.content))
    },

    // add some arbitrary content to entire rows
    map-rows: (row, cells) => cells.map(c =>
        if c == none {
            c
        } else {
            (..c, content: [#c.content\ *R#row*])
        }
    ),

    // color cells based on their columns
    // (using 'fill: (column, row) => color' also works
    // for this particular purpose)
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

#tablex(
    columns: 4,
    fill: blue,
    colspanx(2, rotate(30deg)[a]), rotate(30deg)[a], rotate(30deg)[a],rotate(30deg)[a],
)

#tablex(
    columns: 4,
    stroke: 5pt,
    fill: blue,
    (), vlinex(expand: (-2%, 4pt)),
    [a], [b], [c], [d],
    [e], [f], [g], [h]
)

#set page(width: 300pt)
#pagebreak()
#v(80%)

#tablex(
    columns: 4,
    align: center + horizon,
    auto-vlines: false,
    repeat-header: true,
    header-rows: 2,

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

#v(35em)
#set page(width: auto, height: auto)

#tablex(
    columns: 3,
    [a], [b], [c],
    [d], [e], [f],
    [g], [h], [i],
    [f], [j], [e\ b\ c\ d],
)

#set page(width: 300pt, height: 1000pt)

#tablex(
    columns: (1fr, 1fr, 1fr),
    [a], [b], [c]
)

#table(
    columns: (1fr, 1fr, 1fr),
    [a], [b], [c]
)

#tablex(
    columns: (10%, 10%, 10%, 10%, 10%),
    // map-hlines: h => (..h, stop-pre-gutter: default-if-auto(h.stop-pre-gutter, true)),
    // map-vlines: v => (..v, stop-pre-gutter: default-if-auto(v.stop-pre-gutter, true)),
    gutter: 15pt,
    [a], [b], [c], [d], [e],
    hlinex(stroke: blue),
    [f], rowspanx(2, colspanx(2)[ggggoprdeeteteeeeeee]), (), [i], [j],
    [k], (), (), [n], [o],
    [p], [q], [r], [s], [t]
)
