// Welcome to tablex!
// Feel free to contribute with any features you think are missing.
// Version: v0.0.4

// -- table counter --

#let _tablex-table-counter = counter("_tablex-table-counter")

// -- compat --

#let calc-mod(a, b) = {
  calc.floor(a) - calc.floor(b * calc.floor(a / b))
}
