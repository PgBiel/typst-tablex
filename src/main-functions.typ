// #08
// Main rendering functions:
// 1. Calculator of page dimensions.
// 2. Generation and rendering of row groups (rowspans and header).

// -- tablex imports --
#import "common.typ": *
#import "types.typ": *
#import "type-validators.typ": *
#import "utilities.typ": *
#import "grid.typ": *
#import "col-row-size.typ": *
#import "width-height.typ": *
#import "lines.typ": *
// -- end imports --

// Gets a state variable that holds the page's max x ("width") and max y ("height"),
// considering the left and top margins.
// Requires placing 'get-page-dim-writer(the_returned_state)' on the
// document.
// The id is to differentiate the state for each table.
#let get-page-dim-state(id) = state("tablex_tablex_page_dims__" + repr(id), (width: 0pt, height: 0pt, top_left: none, bottom_right: none))

// A little trick to get the page max width and max height.
// Places a component on the page (or outer container)'s top left,
// and one on the page's bottom right, and subtracts their coordinates.
//
// Must be fed a state variable, which is updated with (width: max x, height: max y).
// The content it returns must be placed in the document for the page state to be
// written to.
//
// NOTE: This function cannot differentiate between the actual page
// and a possible box or block where the component using this function
// could be contained in.
#let get-page-dim-writer() = locate(w_loc => {
    let table_id = _tablex-table-counter.at(w_loc)
    let page_dim_state = get-page-dim-state(table_id)

    place(top + left, locate(loc => {
        page_dim_state.update(s => {
            if s.top_left != none {
                s
            } else {
                let pos = loc.position()
                let width = s.width - pos.x
                let height = s.width - pos.y
                (width: width, height: height, top_left: pos, bottom_right: s.bottom_right)
            }
        })
    }))

    place(bottom + right, locate(loc => {
        page_dim_state.update(s => {
            if s.bottom_right != none {
                s
            } else {
                let pos = loc.position()
                let width = s.width + pos.x
                let height = s.width + pos.y
                (width: width, height: height, top_left: s.top_left, bottom_right: pos)
            }
        })
    }))
})
