// #00
// Welcome to tablex!
// Feel free to contribute with any features you think are missing.
// Version: v0.0.6

// -- table counter --

#let _tablex-table-counter = counter("_tablex-table-counter")

// -- compat --

#let calc-mod(a, b) = {
  calc.floor(a) - calc.floor(b * calc.floor(a / b))
}

// get the types of things so we can compare with them
// (0.2.0-0.7.0: they're strings; 0.8.0+: they're proper types)
#let _array-type = type(())
#let _dict-type = type((a: 5))
#let _bool-type = type(true)
#let _str-type = type("")
#let _color-type = type(red)
#let _stroke-type = type(red + 5pt)
#let _length-type = type(5pt)
#let _rel-len-type = type(100% + 5pt)
#let _ratio-type = type(100%)
#let _int-type = type(5)
#let _float-type = type(5.0)
#let _fraction-type = type(5fr)
#let _function-type = type(x => x)
#let _content-type = type([])
// note: since 0.8.0, alignment and 2d alignment are the same
// but keep it like this for pre-0.8.0
#let _align-type = type(left)
#let _2d-align-type = type(top + left)
