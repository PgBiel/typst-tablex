// #03
// General Typst and table utilities.

// -- tablex imports --
#import "common.typ": *
#import "type-validators.typ": *
// -- end imports --

// Typst 0.9.0 uses a minus sign ("−"; U+2212 MINUS SIGN) for negative numbers.
// Before that, it used a hyphen minus ("-"; U+002D HYPHEN MINUS), so we use
// regex alternation to match either of those.
#let NUMBER_REGEX_STRING = "(−|-)?\\d*\\.?\\d+"

// Which positions does a cell occupy
// (Usually just its own, but increases if colspan / rowspan
// is greater than 1)
#let positions-spanned-by(cell, x: 0, y: 0, x-limit: 0, y-limit: none) = {
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

    if x-limit != none {
        max_x = calc.min(x-limit, max_x)
    }

    if y-limit != none {
        max_y = calc.min(y-limit, max_y)
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
    if type(arr) != _array_type {
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

    if is-infinite-len(len) {
        0pt  // avoid the destruction of the universe
    } else if type(len) == _length_type {
        // E.g., "1pt", "1em", "0.5pt", "0.5em", "1pt + 1em", "-0.5pt + -0.5em"
        // Important notes: there will always be at least one digit before the decimal point
        // for fractional lengths (e.g., .5em becomes "0.5em"). Negative parts will always
        // have a single minus sign or hyphen (depending on the Typst version) in front without
        // any separating space.
        let len-repr = repr(len)

        // Convert the em part.
        //
        // We cannot simply do `len < 0pt` as that will throw an error when `len` has an em component;
        // Typst does not allow comparing lengths containing an em component with lengths that do not.
        //
        // We also need to consider that a length can be positive or negative depending on the current em.
        // E.g., 1em - 1pt will be positive if 1em > 1pt, but negative if 1em < 1pt. It's unfortunately
        // not straightforward, so we handle the absolute and em components separately.
        let em-regex = regex(NUMBER_REGEX_STRING + "em")
        let em-part-repr = len-repr.find(em-regex)
        let (em-part, em-part-in-pt) = if em-part-repr == none {
            (0em, 0pt)
        } else if styles == none {  // em-part-repr is not none at this point (e.g., "1em")
            panic("Cannot convert length to pt ('styles' not specified).")
        } else {  // em-part-repr is not none and styles is also present (i.e., it's valid)
            // SAFETY: guaranteed to be a purely em length by regex
            let em-part = eval(em-part-repr)
            let em-part-in-pt = if em-part >= 0em {
                measure(line(length: em-part), styles).width
            } else  {
                -measure(line(length: -em-part), styles).width
            }

            (em-part, em-part-in-pt)
        }

        // This will be a purely pt length (i.e., no em part).
        let pt-part = len - em-part

        pt-part + em-part-in-pt
    } else if type(len) == _ratio_type {
        if page_size == none {
            panic("Cannot convert ratio to pt ('page_size' not specified).")
        }

        if is-infinite-len(page_size) {
            return 0pt  // page has 'auto' size => % should return 0
        }

        ((len / 1%) / 100) * page_size + 0pt  // e.g. 100% / 1% = 100; / 100 = 1; 1 * page_size
    } else if type(len) == _fraction_type {
        if frac_amount == none {
            panic("Cannot convert fraction to pt ('frac_amount' not specified).")
        }

        if frac_total == none {
            panic("Cannot convert fraction to pt ('frac_total' not specified).")
        }

        if frac_amount <= 0 or is-infinite-len(frac_total) {
            return 0pt
        }

        let len_per_frac = frac_total / frac_amount

        (len_per_frac * (len / 1fr)) + 0pt
    } else if type(len) == _rel_len_type {
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
            assert(type(ratio_part) == _ratio_type, message: "Eval didn't return a ratio")

            let other_part = len - ratio_part  // get the (2em + 5pt) part

            let ratio_part_pt = if is-infinite-len(page_size) { 0pt } else { ((ratio_part / 1%) / 100) * page_size }
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
#let stroke-len(stroke, stroke-auto: 1pt, styles: none) = {
    let no-ratio-error = "Tablex error: Stroke cannot be a ratio or relative length (i.e. have a percentage like '53%'). Try using the layout() function (or similar) to convert the percentage to 'pt' instead."
    let stroke = default-if-auto(stroke, stroke-auto)
    if type(stroke) == _length_type {
        convert-length-to-pt(stroke, styles: styles)
    } else if type(stroke) in (_rel_len_type, _ratio_type) {
        panic(no-ratio-error)
    } else if type(stroke) == _color_type {
        1pt
    } else if type(stroke) == _stroke_type {
        // support:
        // - 5
        // - 5.5
        let maybe-float-regex = "(?:\\d+(?:\\.\\d+)?)"
        // support:
        // - 2pt / 2em / 2cm / 2in   + color
        // - 2.5pt / 2.5em / ...  + color
        // - 2pt + 3em   + color
        let len-regex = "(?:" + maybe-float-regex + "(?:em|pt|cm|in|%)(?:\\s+\\+\\s+" + maybe-float-regex + "em)?)"
        let r = regex("^" + len-regex)
        let s = repr(stroke).find(r)

        if s == none {
            // for more complex strokes, built through dictionaries
            // => "thickness: 5pt" field
            // note: on typst v0.7.0 or later, can just use 's.thickness'
            let r = regex("thickness: (" + len-regex + ")")
            s = repr(stroke).match(r)
            if s != none {
                s = s.captures.first();  // get the first match (the thickness)
            }
        }

        if s == none {
            1pt  // okay it's probably just a color then
        } else {
            let len = eval(s)
            if type(len) == _length_type {
                convert-length-to-pt(len, styles: styles)
            } else if type(len) in (_rel_len_type, _ratio_type) {
                panic(no-ratio-error)
            } else {
                1pt  // should be unreachable
            }
        }
    } else if type(stroke) == _dict_type and "thickness" in stroke {
        let thickness = stroke.thickness
        if type(thickness) == _length_type {
            convert-length-to-pt(thickness, styles: styles)
        } else if type(thickness) in (_rel_len_type, _ratio_type) {
            panic(no-ratio-error)
        } else {
            1pt
        }
    } else {
        1pt
    }
}
