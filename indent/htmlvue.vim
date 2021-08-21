" Vim indent script for html template in Vue files
" Language: HTML in vue template
" Author: Andrey Bartashevich
" Version: 1.0
" Description: Simple indenting rules for html template in vue SFC (single file componenent).
"              Designed for well-formatted code only.
" Abbreviations:
" PNL - previous non-empty line
" CL - current line
" CT - closing tag or closing part of self-closing tag. For the current line closing part of opening
" tag is added.
" OT - opening tag
" Rules:
" Rules are disigned for well-formatted code only.
" Walking through rules from top to bottom. First matching rules defined indent or its shift
" relative PNL.
"
" * First non-empty line => 0
" * CL begins with CT:
" * * CL — '>' and PNL — OT => +1 (special case for plugin vim-closetag)
" * * PNL begins with OT and doesn't end CT => +0
" * * else => -1
" * PNL doesn't contain tags => +0
" * PNL ends with CT => +0
" * PNL begins with OT => +1

if exists('b:did_indent')
  finish
endif
let b:did_indent = 1
setlocal indentexpr=HtmlVueIndent()
setlocal indentkeys=o,O,<>>,!^F
" autoindent: used when the indentexpr returns -1
setlocal autoindent

" Finish, if the function already exists
if exists('*HtmlVueIndent')
  finish
endif

let s:tagname = '\w\+\%\(-\w\+\)*'

" Main indent function. Returns the amount of indent for v:lnum
function! HtmlVueIndent()
  let prev_line_num = prevnonblank(v:lnum - 1)

  " First non-blank line has no indent.
  if prev_line_num == 0
    return 0
  endif

  " Variables
  let cur_line = trim(getline(v:lnum))
  let cur_line_starts_with_closing_tag = cur_line =~ '^</'..s:tagname..'>'
        \ || cur_line =~ '^/>'
        \ || cur_line =~ '^>'
  let prev_line_ind = indent(prev_line_num)
  let prev_line = trim(getline(prev_line_num))
  let prev_line_starts_with_opening_tag = prev_line =~ '^<'..s:tagname
  let prev_line_ends_with_closing_tag = prev_line =~ '</'..s:tagname..'>$'
        \ || prev_line =~ '/>$'
  let prev_line_is_opening_tag = prev_line_starts_with_opening_tag && !prev_line_ends_with_closing_tag && prev_line =~ '>$'
  let prev_line_is_without_tags = !prev_line_starts_with_opening_tag
        \ && !prev_line_ends_with_closing_tag

  if cur_line_starts_with_closing_tag
    echoc "cur_line_starts_with_closing_tag" cur_line
    " Special case for plugin vim-closetag
    if cur_line =~ '^>$' && prev_line_is_opening_tag
      let ind = prev_line_ind + shiftwidth()
    elseif prev_line_starts_with_opening_tag && !prev_line_ends_with_closing_tag
      let ind = prev_line_ind
    else
      let ind = prev_line_ind - shiftwidth()
    endif
  elseif prev_line_is_without_tags
    echoc "prev_line_is_without_tags" prev_line
    let ind = prev_line_ind
  elseif prev_line_ends_with_closing_tag
    echoc "prev_line_ends_with_closing_tag" prev_line
    let ind = prev_line_ind
  elseif prev_line_starts_with_opening_tag
    echoc "prev_line_starts_with_opening_tag" prev_line
    return prev_line_ind + shiftwidth()
  else
    echoc "else"
    let ind = prev_line_ind
  endif

  if ind < 0
    let ind = 0
  endif

  return ind
endfunction
