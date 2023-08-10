// #03
// General Typst and table utilities.

// Which positions does a cell occupy
// (Usually just its own, but increases if colspan / rowspan
// is greater than 1)
#let positions-spanned-by(cell, x: 0, y: 0, x_limit: 0, y_limit: none) = {
    let result = ()
    let rowspan = if "rowspan" in cell { cell.rowspan } else { 1 }
    let colspan = if "colspan" in cell { cell.colspan } else { 1 }

    if rowspan < 1 {
        panic("Cell rowspan must be 1 or greater (bad cell: " + repr((x, y)) + ")")
    } else if colspan < 1 {
        panic("Cell colspan must be 1 or greater (bad cell: " + repr((x, y)) + ")")
    }

    let max_x = x + colspan
    let max_y = y + rowspan

    if x_limit != none {
        max_x = calc.min(x_limit, max_x)
    }

    if y_limit != none {
        max_y = calc.min(y_limit, max_y)
    }

    for x in range(x, max_x) {
        for y in range(y, max_y) {
            result.push((x, y))
        }
    }

    result
}

// initialize an array with a certain element or init function, repeated
#let init-array(amount, element: none, init_function: none) = {
    let nones = ()

    if init_function == none {
        init_function = () => element
    }

    range(amount).map(i => init_function())
}

// Default 'x' to a certain value if it is equal to the forbidden value
// ('none' by default)
#let default-if-not(x, default, if_isnt: none) = {
    if x == if_isnt {
        default
    } else {
        x
    }
}

// Default 'x' to a certain value if it is none
#let default-if-none(x, default) = default-if-not(x, default, if_isnt: none)

// Default 'x' to a certain value if it is auto
#let default-if-auto(x, default) = default-if-not(x, default, if_isnt: auto)

// Default 'x' to a certain value if it is auto or none
#let default-if-auto-or-none(x, default) = if x in (auto, none) {
    default
} else {
    x
}

// The max between a, b, or the other one if either is 'none'.
#let max-if-not-none(a, b) = if a in (none, auto) {
    b
} else if b in (none, auto) {
    a
} else {
    calc.max(a, b)
}

// Backwards-compatible enumerate
#let enumerate(arr) = {
    if type(arr) != "array" {
        return arr
    }

    let new-arr = ()
    let i = 0

    for x in arr {
        new-arr.push((i, x))

        i += 1
    }

    new-arr
}

// Gets the topmost parent of a line.
#let get-top-parent(line) = {
    let previous = none
    let current = line

    while current != none {
        previous = current
        current = previous.parent
    }

    previous
}

// Convert a certain (non-relative) length to pt
//
// styles: from style()
// page_size: equivalent to 100%
// frac_amount: amount of 'fr' specified
// frac_total: total space shared by fractions
#let convert-length-to-pt(
    len,
    styles: none, page_size: none, frac_amount: none, frac_total: none
) = {
    page_size = 0pt + page_size

    if type(len) == "length" {
        if "em" in repr(len) {
            if styles == none {
                panic("Cannot convert length to pt ('styles' not specified).")
            }

            measure(line(length: len), styles).width + 0pt
        } else {
            len + 0pt  // mm, in, pt
        }
    } else if type(len) == "ratio" {
        if page_size == none {
            panic("Cannot convert ratio to pt ('page_size' not specified).")
        }

        ((len / 1%) / 100) * page_size + 0pt  // e.g. 100% / 1% = 100; / 100 = 1; 1 * page_size
    } else if type(len) == "fraction" {
        if frac_amount == none {
            panic("Cannot convert fraction to pt ('frac_amount' not specified).")
        }

        if frac_total == none {
            panic("Cannot convert fraction to pt ('frac_total' not specified).")
        }

        if frac_amount <= 0 {
            return 0pt
        }

        let len_per_frac = frac_total / frac_amount

        (len_per_frac * (len / 1fr)) + 0pt
    } else if type(len) == "relative length" {
        if styles == none {
            panic("Cannot convert relative length to pt ('styles' not specified).")
        }

        let ratio_regex = regex("^\\d+%")
        let ratio = repr(len).find(ratio_regex)

        if ratio == none {  // 2em + 5pt  (doesn't contain 100% or something)
            measure(line(length: len), styles).width
        } else {  // 100% + 2em + 5pt  --> extract the "100%" part
            if page_size == none {
                panic("Cannot convert relative length to pt ('page_size' not specified).")
            }

            // SAFETY: guaranteed to be a ratio by regex
            let ratio_part = eval(ratio)
            assert(type(ratio_part) == "ratio", message: "Eval didn't return a ratio")

            let other_part = len - ratio_part  // get the (2em + 5pt) part

            let ratio_part_pt = ((ratio_part / 1%) / 100) * page_size
            let other_part_pt = 0pt

            if other_part < 0pt {
                other_part_pt = -measure(line(length: -other_part), styles).width
            } else {
                other_part_pt = measure(line(length: other_part), styles).width
            }

            ratio_part_pt + other_part_pt + 0pt
        }
    } else {
        panic("Cannot convert '" + type(len) + "' to length.")
    }
}

// Convert a stroke to its thickness
#let stroke-len(stroke, stroke-auto: 1pt) = {
    let stroke = default-if-auto(stroke, stroke-auto)
    if type(stroke) in ("length", "relative length") {
        stroke
    } else if type(stroke) == "color" {
        1pt
    } else if type(stroke) == "stroke" {  // 2em + blue
        let r = regex("^\\d+(?:em|pt|cm|in|%)")
        let s = repr(stroke).find(r)

        if s == none {
        1pt
        } else {
        eval(s)
        }
    } else if type(stroke) == "dictionary" and "thickness" in stroke {
        stroke.thickness
    } else {
        1pt
    }
}

