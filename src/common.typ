// #00
// Welcome to tablex!
// Feel free to contribute with any features you think are missing.
// Version: v0.0.6

// -- table counter --

#let _tablex-table-counter = counter("_tablex-table-counter")

// -- compat --

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

// Attachments use "t" and "b" instead of "top" and "bottom" since v0.3.0.
#let using-typst-v030-or-later = using-typst-v080-or-later or $a^b$.body.has("t")

// This is true if types have fields in the current Typst version.
// This means we can use stroke.thickness, length.em, and so on.
#let typst-fields-supported = using-typst-v080-or-later

// This is true if calc.rem exists in the current Typst version.
// Otherwise, we use a polyfill.
#let typst-calc-rem-supported = using-typst-v030-or-later

// Remainder operation.
#let calc-mod = if typst-calc-rem-supported {
  calc.rem
} else {
  (a, b) => calc.floor(a) - calc.floor(b * calc.floor(a / b))
}

// Returns the sign of the operand.
// -1 for negative, 1 for positive or zero.
#let calc-sign(x) = {
  // For positive: true - false = 1 - 0 = 1
  // For zero: true - false = 1 - 0 = 1
  // For negative: false - true = 0 - 1 = -1
  int(0 <= x) - int(x < 0)
}

// Polyfill for array sum (.sum() is Typst 0.3.0+).
#let array-sum(arr, zero: 0) = {
  arr.fold(zero, (a, x) => a + x)
}

// -- common validators --

// Converts the 'fit-spans' argument to a (x: bool, y: bool) dictionary.
// Optionally use a default dictionary to fill missing arguments with.
// This is in common.typ as it is needed by grid.typ as well.
#let validate-fit-spans(fit-spans, default: (x: false, y: false), error-prefix: none) = {
  if type(error-prefix) == _str-type {
    error-prefix = " " + error-prefix
  } else {
    error-prefix = ""
  }
  if type(fit-spans) == _bool-type {
    fit-spans = (x: fit-spans, y: fit-spans)
  }
  if type(fit-spans) == _dict-type {
    assert(fit-spans.len() > 0, message: "Tablex error:" + error-prefix + " 'fit-spans', if a dictionary, must not be empty.")
    assert(fit-spans.keys().all(k => k in ("x", "y")), message: "Tablex error:" + error-prefix + " 'fit-spans', if a dictionary, must only have the keys x and y.")
    assert(fit-spans.values().all(v => type(v) == _bool-type), message: "Tablex error:" + error-prefix + " keys 'x' and 'y' in the 'fit-spans' dictionary must be booleans (true/false).")
    for key in ("x", "y") {
      if key in default and key not in fit-spans {
        fit-spans.insert(key, default.at(key))
      }
    }
  } else {
    panic("Tablex error:" + error-prefix + " Expected 'fit-spans' to be either a boolean or dictionary, found '" + str(type(fit-spans)) + "'")
  }
  fit-spans
}
