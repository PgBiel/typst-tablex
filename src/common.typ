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
#let _array_type = type(())
#let _dict_type = type((a: 5))
#let _str_type = type("")
#let _color_type = type(red)
#let _stroke_type = type(red + 5pt)
#let _length_type = type(5pt)
#let _rel_len_type = type(100% + 5pt)
#let _ratio_type = type(100%)
#let _int_type = type(5)
#let _float_type = type(5.0)
#let _fraction_type = type(5fr)
#let _function_type = type(x => x)
#let _content_type = type([])
// note: since 0.8.0, alignment and 2d alignment are the same
// but keep it like this for pre-0.8.0
#let _align_type = type(left)
#let _2d_align_type = type(top + left)
