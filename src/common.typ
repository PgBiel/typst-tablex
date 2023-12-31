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

// Returns the sign of the operand.
// -1 for negative, 1 for positive or zero.
#let calc-sign(x) = {
  // For positive: true - false = 1 - 0 = 1
  // For zero: true - false = 1 - 0 = 1
  // For negative: false - true = 0 - 1 = -1
  int(0 <= x) - int(x < 0)
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

// If types aren't strings, this means we're using 0.8.0+.
#let using-typst-v080-or-later = str(type(_str-type)) == "type"

// This is true if types have fields in the current Typst version.
// This means we can use stroke.thickness, length.em, and so on.
#let typst-fields-supported = using-typst-v080-or-later
