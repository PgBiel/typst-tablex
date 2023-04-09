#import "tablex.typ": *

#place(top+left, locate(loc => loc.position()))

*Test*

test

// #show: it => style(styles => {
//     [#repr(it)]
//     [#measure(it, styles)]
    
//     [#it]
// })


#let ee = state("T", none)

#let d = place(bottom+right, locate(loc => {
    ee.update(t => loc.position())
}))

#d
r

e 

#line(length: 100%)
#locate(loc => {
    let pos = ee.at(loc)
    if pos != none {
        line(length: pos.x - loc.position().x)
    }
})
// ddd
// #locate(loc => repr(loc.position()))

#(100%, 1fr, 100% - 1pt, 1em).map(type)

#{
    box(width: 1fr, line(length: 100%))
    box(width: 1fr, line(stroke: blue, length: 100%))
    box(width: auto, line(stroke: red, length: 100%))
}

#let b = box(width: 100%)[]
#let a = rotate(45deg, table(columns: (100%,), table(columns: (100%,), [a])))
#a
#style(styles => measure(box(width: 1em), styles))

#line(length: 11pt)
#line(length: 1em)

#style(styles => convert-length-to-pt(2fr, styles: styles, page_size: 500pt, frac_total: 300pt, frac_amount: 4))

// #{calc.floor(autrrtttrro)}rrereeee
deeteeeeeeeeedett
#tablex(
    columns: (auto, auto, auto), // rows: ((1em, 1em, 1em),) eeee
    rows: (auto,),
    align: (column, row) => {(top, center).at(calc.mod(row + column, 2))},
    // fill: (column, row) => {(blue, red).at(calc.mod(row + column, 2))},
    vline(), vline(), vline(), vline(),
    hline(),
    [*My*], colspan(2)[*Headedr*],  //
    hline(start: 0, end: 1),
    cellx(colspan: 2, rowspan: 2)[a], [b\ c],
    hline(),
    () , (), [cefdseerd],
    hline(),
    [a], [b], [xyz],
    hline(end: 1),
    [b],
    hline(),
    ..range(0, 25).map(i => ([d], [#{i + 3}], [a],
    hline())).flatten(),
    [b], [c],
)

#tablex(
    columns: 5,
    rows: 1,
    stroke: red + 2pt,
    vline(), vline(), vline(), vline(), vline(), vline(),
    hline(),
    [abcdef], colspan(3, rowspan(2, [ee], fill: red), align: horizon), (), (), [c],
    hline(stroke: blue),
    [abcdef], (), (), (), [c],
    hline(),
    [aa], [b], [c], [b], cellx(inset: 2pt, align: center+horizon)[cdeecfeeeeetec],
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
    [a], [b], [c], [d],
    hline(),
    [a], colspan(2, rowspan(2)[b]), [d],
    [a], (), (), [d],
    [a], [b], [c], [d],
)

#tablex(
    columns: (1em, 1em, auto, auto),
    rows: (1em, 1em, auto),
    [a], [b], [cd], [d],
    hline(),
    [a], colspan(2, rowspan(2)[bcccccccc\ c\ c\ c]), [d],
    [a], (), (), [d],
    [a], [e], [f], [d],
    [a], [b], [c], [de],
)

eeeedreeteteederttddeerreeteeeeeerettededteeedeceesdeedeeefteetdedeeesefdfrreeedeefgederdaeeteeeeddrdffteeeeeeeeesedteteestderedeeeeefeeeeessde

s
