" Vim indent script for html template in Vue files
" Language: HTML in vue template
" Author: Andrey Bartashevich
" Version: 1.0
" Description: Simple indenting rules for html template in vue SFC (single file componenent).
"              Designed for well-formatted code only.

if exists('b:did_indent')
  finish
endif
let b:did_indent = 1
setlocal indentexpr=HtmlVueIndent()
setlocal indentkeys=o,O,<>>,*<Return>,0},0],0),!^F
" autoindent: used when the indentexpr returns -1
setlocal autoindent

" Finish, if the function already exists
if exists('*HtmlVueIndent')
  finish
endif

let s:debug_indent = v:false
if exists('g:vue_debug_indent')
  let s:debug_indent = g:vue_debug_indent
endif

let s:log_file = expand('<sfile>:h')..'/indent.log'
let s:tagname = '\w\+\%\(-\w\+\)*'

function! s:Log(text, new_line = 1)
  if s:debug_indent
    execute 'redir >>'..s:log_file
    if a:new_line
      silent echo a:text
    else
      silent echon a:text
    endif
    redir END
  endif
endfunction

" Main indent function. Returns the amount of indent for v:lnum
function! HtmlVueIndent()
  " Variables
  let prev_line_num = prevnonblank(v:lnum - 1)

  " First non-blank line has no indent.
  if prev_line_num == 0
    return 0
  endif

  let before_prev_line_num = prevnonblank(prev_line_num - 1)
  let before_prev_line = ''
  if before_prev_line_num != 0
    let before_prev_line = trim(getline(before_prev_line_num))
  endif
  let before_prev_line_ends_with_unclosed_closing_tag = before_prev_line =~ '</'..s:tagname..'$'

  let cur_line = trim(getline(v:lnum))
  let cur_line_is_comment_end = cur_line =~ '^-->$'
  let cur_line_starts_with_closing_tag = cur_line =~ '^</'..s:tagname..'>'
        \ || cur_line =~ '^/>'
        \ || cur_line =~ '^>'
  let cur_line_ends_with_unclosed_closing_tag = cur_line =~ '</'..s:tagname..'$'

  let prev_line = trim(getline(prev_line_num))
  let prev_line_ind = indent(prev_line_num)
  let prev_line_is_comment_start = prev_line =~ '^<!--$'
  let prev_line_starts_with_opening_tag = prev_line =~ '^<'..s:tagname
        \ || (prev_line =~ '^>$' && !before_prev_line_ends_with_unclosed_closing_tag)
  let prev_line_ends_with_closing_tag = prev_line =~ '</'..s:tagname..'>$'
        \ || prev_line =~ '/>$'
        \ || (prev_line =~ '^>$' && before_prev_line_ends_with_unclosed_closing_tag)
  let prev_line_is_opening_tag = prev_line_starts_with_opening_tag
        \ && !prev_line_ends_with_closing_tag
        \ && prev_line =~ '>$'
  let prev_line_ends_with_opening_tag = prev_line =~ '<'..s:tagname..'[^>]*>\?$'
  let prev_line_is_without_tags = !prev_line_starts_with_opening_tag
        \ && !prev_line_ends_with_closing_tag
        \ && !prev_line_ends_with_opening_tag
  let prev_line_ends_with_unclosed_closing_tag = prev_line =~ '</'..s:tagname..'$'

  " Rules
  if cur_line_is_comment_end
    call s:Log('cur_line_is_comment_end '..cur_line)
    if prev_line_is_comment_start
      let ind = prev_line_ind
    else
      let ind = prev_line_ind - shiftwidth()
    endif

  elseif prev_line_is_comment_start
    call s:Log('prev_line_is_comment_start '..prev_line)
    let ind = prev_line_ind + shiftwidth()

  elseif cur_line =~ '^}}'
    call s:Log('cur_line_starts_with_}} '..cur_line)
    call s:Log('prev_line: '..prev_line)
    let line_num = search('{{$', 'bnW')
    if line_num != 0
      let ind = indent(line_num)
    else
      let ind = prev_line_ind - shiftwidth()
    endif

  elseif prev_line =~ '{{$'
    call s:Log('prev_line_ends_with_{{ '..prev_line)
    let ind = prev_line_ind + shiftwidth()

  elseif cur_line =~ '^}'
    call s:Log('cur_line_starts_with_} '..cur_line)
    call s:Log('prev_line: '..prev_line)
    let line_num = search('{$', 'bnW')
    if line_num != 0
      let ind = indent(line_num)
    else
      let ind = prev_line_ind - shiftwidth()
    endif

  elseif prev_line =~ '{$'
    call s:Log('prev_line_ends_with_{ '..prev_line)
    let ind = prev_line_ind + shiftwidth()

  elseif cur_line =~ '^]'
    call s:Log('cur_line_starts_with_] '..cur_line)
    call s:Log('prev_line: '..prev_line)
    let line_num = search('[$', 'bnW')
    if line_num != 0
      let ind = indent(line_num)
    else
      let ind = prev_line_ind - shiftwidth()
    endif

  elseif prev_line =~ '[$'
    call s:Log('prev_line_ends_with_[ '..prev_line)
    let ind = prev_line_ind + shiftwidth()

  elseif cur_line =~ '^)'
    call s:Log('cur_line_starts_with_) '..cur_line)
    call s:Log('prev_line: '..prev_line)
    let line_num = search('($', 'bnW')
    if line_num != 0
      let ind = indent(line_num)
    else
      let ind = prev_line_ind - shiftwidth()
    endif

  elseif prev_line =~ '($'
    call s:Log('prev_line_ends_with_( '..prev_line)
    let ind = prev_line_ind + shiftwidth()

  elseif cur_line =~ '^"$'
    call s:Log('cur_line_is_" ')
    call s:Log('prev_line: '..prev_line)
    let line_num = search('="$', 'bnW')
    if line_num != 0
      let ind = indent(line_num)
    else
      let ind = prev_line_ind - shiftwidth()
    endif

  elseif prev_line =~ '="$'
    call s:Log('prev_line_ends_with_=" '..prev_line)
    let ind = prev_line_ind + shiftwidth()

  elseif cur_line =~ '^? '
    call s:Log('ternary operator')
    let ind = prev_line_ind + shiftwidth()

  elseif prev_line =~ '^: '
    call s:Log('after ternary operator')
    let ind = prev_line_ind - shiftwidth()

  elseif cur_line_starts_with_closing_tag
    call s:Log('cur_line_starts_with_closing_tag '..cur_line)
    " Special case for plugin vim-closetag
    if cur_line =~ '^>$' && (prev_line_is_opening_tag || prev_line_ends_with_opening_tag)
      call s:Log(' if', 0)
      let ind = prev_line_ind + shiftwidth()
    elseif cur_line =~ '^/\?></'..s:tagname..'>$'
      call s:Log(' elseif1', 0)
      let tagname = matchstr(cur_line, '^/\?></\zs'..s:tagname..'\ze>$')
      let line_num = search('<'..tagname, 'bnW')
      if line_num != 0
        let ind = indent(line_num)
      else
        let ind = prev_line_ind - shiftwidth()
      endif
    elseif cur_line =~ '^>' && prev_line_ends_with_unclosed_closing_tag
      call s:Log(' elseif2', 0)
      let tagname = matchstr(prev_line, '</\zs'..s:tagname..'\ze$')
      let line_num = search('<'..tagname, 'bnW')
      if line_num != 0
        let ind = indent(line_num)
      else
        let ind = prev_line_ind
      endif
    elseif cur_line =~ '^>' && cur_line_ends_with_unclosed_closing_tag
      call s:Log(' elseif3', 0)
      if (prev_line_starts_with_opening_tag || prev_line_ends_with_opening_tag)
        let ind = prev_line_ind + shiftwidth()
      elseif prev_line_ends_with_unclosed_closing_tag
        let ind = prev_line_ind - shiftwidth()
      else
        let ind = prev_line_ind
      endif
    elseif prev_line_starts_with_opening_tag && !prev_line_ends_with_closing_tag
      call s:Log(' elseif4', 0)
      if cur_line =~ '^</'..s:tagname..'>$'
        let tagname = matchstr(cur_line, '^</\zs'..s:tagname..'\ze>$')
        let line_num = search('<'..tagname, 'bnW')
        if line_num != 0
          let ind = indent(line_num)
        else
          let ind = prev_line_ind
        endif
      else
        let ind = prev_line_ind + shiftwidth()
      endif
    elseif cur_line =~ '^>[^<>]\+$' " >Текст кнопки
      call s:Log(' elseif4', 0)
      let ind = prev_line_ind
    else
      call s:Log(' else', 0)
      let ind = prev_line_ind - shiftwidth()
    endif

  elseif prev_line_is_without_tags
    call s:Log('prev_line_is_without_tags '..prev_line)
    let ind = prev_line_ind

  elseif prev_line_ends_with_closing_tag
    call s:Log('prev_line_ends_with_closing_tag '..prev_line)
    let ind = prev_line_ind

  elseif prev_line_starts_with_opening_tag
    call s:Log('prev_line_starts_with_opening_tag '..prev_line)
    let ind = prev_line_ind + shiftwidth()

  elseif prev_line_ends_with_opening_tag
    call s:Log('prev_line_ends_with_opening_tag '..prev_line)
    let ind = prev_line_ind + shiftwidth()

  else
    call s:Log('else')
    let ind = prev_line_ind
  endif

  if ind < 0
    let ind = 0
  endif

  return ind
endfunction
