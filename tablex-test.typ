#import "tablex.typ": *

*Test*

test

#tabular(
    columns: (auto, auto, auto), // rows: (1em, 1em, 1em),
    align: (column, row) => {(top, center).at(calc.mod(row + column, 2))},
    fill: (column, row) => {(blue, red).at(calc.mod(row + column, 2))},
    vline(), vline(), vline(), vline(),
    hline(),
    [*My*], colspan(length: 2)[*Header*],  //
    hline(start: 0, end: 1),
    tcell(colspan: 2, rowspan: 2)[a], [b\ c],
    hline(),
    () , (), [c],
    hline(),
    [a], [b], [xyz],
    hline(),
    ..range(0, 35).map(i => ([d], [#{i + 3}], [a],
    hline())).flatten(),
)
eeeedr
