// #03
// General Typst and table utilities.

// -- tablex imports --
#import "common.typ": *
#import "type-validators.typ": *
// -- end imports --

// Typst 0.9.0 uses a minus sign ("−"; U+2212 MINUS SIGN) for negative numbers.
// Before that, it used a hyphen minus ("-"; U+002D HYPHEN MINUS), so we use
// regex alternation to match either of those.
#let NUMBER-REGEX-STRING = "(?:−|-)?\\d*\\.?\\d+"

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

    let max-x = x + colspan
    let max-y = y + rowspan

    if x-limit != none {
        max-x = calc.min(x-limit, max-x)
    }

    if y-limit != none {
        max-y = calc.min(y-limit, max-y)
    }

    for x in range(x, max-x) {
        for y in range(y, max-y) {
            result.push((x, y))
        }
    }

    result
}

// initialize an array with a certain element or init function, repeated
#let init-array(amount, element: none, init-function: none) = {
    let nones = ()

    if init-function == none {
        init-function = () => element
    }

    range(amount).map(i => init-function())
}

// Default 'x' to a certain value if it is equal to the forbidden value
// ('none' by default)
#let default-if-not(x, default, if-isnt: none) = {
    if x == if-isnt {
        default
    } else {
        x
    }
}

// Default 'x' to a certain value if it is none
#let default-if-none(x, default) = default-if-not(x, default, if-isnt: none)

// Default 'x' to a certain value if it is auto
#let default-if-auto(x, default) = default-if-not(x, default, if-isnt: auto)

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
    if type(arr) != _array-type {
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

// Measure a length in pt by drawing a line and using the measure() function.
// This function will work for negative lengths as well.
//
// Note that for ratios, the measurement will be 0pt due to limitations of
// the "draw and measure" technique (wrapping the line in a box still returns 0pt;
// not sure if there is any viable way to measure a ratio). This also affects
// relative lengths — this function will only be able to measure the length component.
//
// styles: from style()
#let measure-pt(len, styles) = {
    let measured-pt = measure(box(width: len), styles).width

    // If the measured length is positive, `len` must have overall been positive.
    // There's nothing else to be done, so return the measured length.
    if measured-pt > 0pt {
        return measured-pt
    }

    // If we've reached this point, the previously measured length must have been `0pt`
    // (drawing a line with a negative length will draw nothing, so measuring it will return `0pt`).
    // Hence, `len` must either be `0pt` or negative.
    // We multiply `len` by -1 to get a positive length, draw a line and measure it, then negate
    // the measured length. This nicely handles the `0pt` case as well.
    measured-pt = -measure(box(width: -len), styles).width
    return measured-pt
}

// Convert a length of type length to pt.
//
// styles: from style()
#let convert-length-type-to-pt(len, styles: none) = {
    // repr examples: "1pt", "1em", "0.5pt", "0.5em", "1pt + 1em", "-0.5pt + -0.5em"
    if "em" not in repr(len) {
        // No need to do any conversion because it must already be in pt.
        return len
    }

    // At this point, we will need to draw a line for measurement,
    // so we need the styles.
    if styles == none {
        panic("Cannot convert length to pt ('styles' not specified).")
    }

    return measure-pt(len, styles)
}

// Convert a ratio type length to pt
//
// page-size: equivalent to 100%
#let convert-ratio-type-to-pt(len, page-size) = {
    assert(
        is-purely-pt-len(page-size),
        message: "'page-size' should be a purely pt length"
    )

    if page-size == none {
        panic("Cannot convert ratio to pt ('page-size' not specified).")
    }

    if is-infinite-len(page-size) {
        return 0pt  // page has 'auto' size => % should return 0
    }

    ((len / 1%) / 100) * page-size + 0pt  // e.g. 100% / 1% = 100; / 100 = 1; 1 * page-size
}

// Convert a fraction type length to pt
//
// frac-amount: amount of 'fr' specified
// frac-total: total space shared by fractions
#let convert-fraction-type-to-pt(len, frac-amount, frac-total) = {
    assert(
        is-purely-pt-len(frac-total),
        message: "'frac-total' should be a purely pt length"
    )

    if frac-amount == none {
        panic("Cannot convert fraction to pt ('frac-amount' not specified).")
    }

    if frac-total == none {
        panic("Cannot convert fraction to pt ('frac-total' not specified).")
    }

    if frac-amount <= 0 or is-infinite-len(frac-total) {
        return 0pt
    }

    let len-per-frac = frac-total / frac-amount

    (len-per-frac * (len / 1fr)) + 0pt
}

// Convert a relative type length to pt
//
// styles: from style()
// page-size: equivalent to 100% (optional because the length may not have a ratio component)
#let convert-relative-type-to-pt(len, styles, page-size: none) = {
    // We will need to draw a line for measurement later,
    // so we need the styles.
    if styles == none {
        panic("Cannot convert relative length to pt ('styles' not specified).")
    }

    if eval(repr(0.00005em)) != 0.00005em {
        // em repr changed in 0.11.0 => can safely use fields here
        return convert-ratio-type-to-pt(len.ratio, page-size) + convert-length-type-to-pt(len.length, styles: styles)
    }

    // Note on precision: the `repr` for em components is precise, unlike
    // other length components, which are rounded to a precision of 2.
    // This is true up to Typst 0.9.0 and possibly later versions.
    let em-regex = regex(NUMBER-REGEX-STRING + "em")
    let em-part-repr = repr(len).find(em-regex)

    // Calculate the length minus its em component.
    // E.g., 1% + 1pt + 1em -> 1% + 1pt
    let (em-part, len-minus-em) = if em-part-repr == none {
        (0em, len)
    } else {
        // SAFETY: guaranteed to be a purely em length by regex
        let em-part = eval(em-part-repr)
        (em-part, len - em-part)
    }

    // This will give only the pt part of the length.
    // E.g., 1% + 1pt -> 1pt
    // See the documentation on measure-pt for more information.
    let pt-part = measure-pt(len-minus-em, styles)

    // Since we have the values of the em and pt components,
    // we can calculate the ratio part.
    let ratio-part = len-minus-em - pt-part
    let ratio-part-pt = if ratio-part == 0% {
        // No point doing `convert-ratio-type-to-pt` if there's no ratio component.
        0pt
    } else {
        convert-ratio-type-to-pt(ratio-part, page-size)
    }

    // The length part is the pt part + em part.
    // Note: we cannot use `len - ratio-part` as that returns a `_rel-len-type` value,
    // not a `_length-type` value.
    let length-part-pt = convert-length-type-to-pt(pt-part + em-part, styles: styles)

    ratio-part-pt + length-part-pt
}

// Convert a certain (non-relative) length to pt
//
// styles: from style()
// page-size: equivalent to 100%
// frac-amount: amount of 'fr' specified
// frac-total: total space shared by fractions
#let convert-length-to-pt(
    len,
    styles: none, page-size: none, frac-amount: none, frac-total: none
) = {
    page-size = 0pt + page-size

    if is-infinite-len(len) {
        0pt  // avoid the destruction of the universe
    } else if type(len) == _length-type {
        convert-length-type-to-pt(len, styles: styles)
    } else if type(len) == _ratio-type {
        convert-ratio-type-to-pt(len, page-size)
    } else if type(len) == _fraction-type {
        convert-fraction-type-to-pt(len, frac-amount, frac-total)
    } else if type(len) == _rel-len-type {
        convert-relative-type-to-pt(len, styles, page-size: page-size)
    } else {
        panic("Cannot convert '" + type(len) + "' to length.")
    }
}

// Convert a stroke to its thickness
#let stroke-len(stroke, stroke-auto: 1pt, styles: none) = {
    let no-ratio-error = "Tablex error: Stroke cannot be a ratio or relative length (i.e. have a percentage like '53%'). Try using the layout() function (or similar) to convert the percentage to 'pt' instead."
    let stroke = default-if-auto(stroke, stroke-auto)
    if type(stroke) == _length-type {
        convert-length-to-pt(stroke, styles: styles)
    } else if type(stroke) in (_rel-len-type, _ratio-type) {
        panic(no-ratio-error)
    } else if is-color(stroke) {
        1pt
    } else if type(stroke) == _stroke-type {
        // support:
        // - 2pt / 2em / 2cm / 2in   + color
        // - 2.5pt / 2.5em / ...  + color
        // - 2pt + 3em   + color
        let len-regex = "(?:" + NUMBER-REGEX-STRING + "(?:em|pt|cm|in|%)(?:\\s+\\+\\s+" + NUMBER-REGEX-STRING + "em)?)"
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
            if type(len) == _length-type {
                convert-length-to-pt(len, styles: styles)
            } else if type(len) in (_rel-len-type, _ratio-type) {
                panic(no-ratio-error)
            } else {
                1pt  // should be unreachable
            }
        }
    } else if type(stroke) == _dict-type and "thickness" in stroke {
        let thickness = stroke.thickness
        if type(thickness) == _length-type {
            convert-length-to-pt(thickness, styles: styles)
        } else if type(thickness) in (_rel-len-type, _ratio-type) {
            panic(no-ratio-error)
        } else {
            1pt
        }
    } else {
        1pt
    }
}
