if exists('b:did_indent')
  finish
endif
let b:did_indent = 1

function! s:SetHtmlIndent()
  let s:empty_tagname = '(area|base|br|col|embed|hr|input|img|'
        \.'keygen|link|meta|param|source|track|wbr)'
  let s:empty_tag = '\v\<'.s:empty_tagname.'.*(/)@<!\>'
  let s:empty_tag_start = '\v\<'.s:empty_tagname.'[^>]*$'
  let s:empty_tag_end = '\v^\s*[^<>/]*\/?\>\s*'
  let s:tag_start = '\v^\s*\<\w*'   " <
  let s:tag_end = '\v^\s*\/?\>\s*'  " />
  let s:full_tag_end = '\v^\s*\<\/' " </...>
  let s:ternary_q = '^\s\+?'
  let s:ternary_e = '^\s\+:.*,\s*$'

  unlet! b:did_indent
  let &l:indentexpr = ''
  execute 'runtime lib/xml.vim'
  let s:orig_indentexpr = &l:indentexpr

  setlocal indentkeys=o,O,<Return>,<>>,<<>,{,},!^F
  setlocal indentexpr=HtmlIndent()
endfunction

function! s:PrevMultilineEmptyTag(lnum)
  let lnum = a:lnum - 1
  let lnums = [0, 0]
  while lnum > 0
    let line = getline(lnum)
    if line =~? s:empty_tag_end
      let lnums[1] = lnum
    endif

    if line =~? s:tag_start
      if line =~? s:empty_tag_start
        let lnums[0] = lnum
        return lnums
      else
        return [0, 0]
      endif
    endif

    let lnum = lnum - 1
  endwhile
endfunction

function! s:AdjustIndent(ind)
  let ind = a:ind
  let prevlnum = prevnonblank(v:lnum - 1)
  let prevline = getline(prevlnum)
  let curline = getline(v:lnum)

  if prevline =~? s:empty_tag
    let ind = ind - &sw
  endif

  " Align '/>' and '>' with '<'
  if curline =~? s:tag_end
    let ind = ind - &sw
  endif
  " Then correct the indentation of any element following '/>' or '>'.
  if prevline =~? s:tag_end
    let ind = ind + &sw

    " Decrease indent if prevlines are a multiline empty tag
    let [start, end] = s:PrevMultilineEmptyTag(v:lnum)
    if prevlnum == end
      let ind = indent(v:lnum - 1)
      if curline =~? s:full_tag_end
        let ind = ind - &sw
      endif
    endif
  endif

  " Multiline array/object in attribute like v-*="[
  "   ...
  " ]
  if prevline =~ '[[{]\s*$'
    let ind = indent(prevlnum) + &sw
  endif
  if curline =~ '^\s*[]}][^"]*"\?\s*$'
    let ind = indent(prevlnum) - &sw
  endif

  " Multiline ternary 'a ? b : c' in attribute
  if curline =~ s:ternary_q
    let ind = indent(prevlnum) + &sw
  endif
  if curline =~ s:ternary_e && prevline =~ s:ternary_q
    let ind = indent(prevlnum)
  endif
  if prevline =~ s:ternary_e
    let ind = indent(prevlnum) - &sw
  endif

  " Angle bracket in attribute, like v-if="isEnabled('item.<name>')"
  if prevline =~ '="[^"]*<[^"]*>[^"]*"'
    let ind = ind - &sw
  endif

  return ind
endfunction

function! HtmlIndent()
  let ind = eval(s:orig_indentexpr)
  let ind = s:AdjustIndent(ind)
  return ind
endfunction

call s:SetHtmlIndent()
