" ============================================================================
" File:         plugin/readline.vim
" Description:  Readline-style mappings for command-line mode
" Authors:      Elias Astrom <github.com/ryvnf>,
"               Jakub Bortlik <github.com/jakubbortlik>
" Last Change:  2025-09-17
" License:      The VIM LICENSE
" ============================================================================

if exists('g:loaded_readline') || &compatible
  finish
endif
let g:loaded_readline = 1

"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
" ALT mappings
"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

" delete back to start of word
cnoremap <expr> <Esc><BS> <SID>rubout_word()

" move back to start of word
cnoremap <expr> <Esc>b <SID>back_word()

" make word capitalized
cnoremap <expr> <Esc>c <SID>capitalize_word()
cnoremap <expr> <Esc>C <SID>capitalize_word()

" delete forward to end of word
cnoremap <expr> <Esc>d <SID>delete_word()

" move forward to end of word
cnoremap <expr> <Esc>f <SID>forward_word()

" make word lowercase
cnoremap <expr> <Esc>l <SID>downcase_word()
cnoremap <expr> <Esc>L <SID>downcase_word()

" transpose words before cursor
cnoremap <expr> <Esc>t <SID>transpose_words()
cnoremap <expr> <Esc>T <SID>transpose_words()

" make word uppercase
cnoremap <expr> <Esc>u <SID>upcase_word()
cnoremap <expr> <Esc>U <SID>upcase_word()

" comment out line and execute it
cnoremap <Esc># <C-B>"<CR>

" list all completion matches
cnoremap <Esc>? <C-D>
cnoremap <Esc>= <C-D>

" insert all completion matches
cnoremap <Esc>* <C-A>

" insert last word from last command
cnoremap <expr> <Esc>. <SID>last_cmd_word()

"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
" CTRL mappings
"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

" move to start of line
inoremap        <C-A> <C-O>^
inoremap   <C-X><C-A> <C-A>
cnoremap        <C-A> <Home>
cnoremap   <C-X><C-A> <C-A>

" move to next char
noremap! <C-B> <Left>

" delete char under cursor
inoremap <expr> <C-D> col('.') <= strlen(getline('.')) ? "\<Del>" : "\<C-d>"
cnoremap <expr> <C-D> getcmdpos() <= strlen(getcmdline()) ? "\<Del>" : "\<C-d>"

" move to end of line
inoremap <expr> <C-E> col('.')>strlen(getline('.'))<Bar><Bar>pumvisible()?"\<C-E>":"\<End>"
cnoremap <C-E> <End>

" move to next char
inoremap <C-F> <Right>
cnoremap <expr> <C-F> getcmdpos()>strlen(getcmdline())?&cedit:"\<Right>"

" delete back to start of word
cnoremap <expr> <esc><bs> <sid>rubout_word()

"" delete to start of line
cnoremap <expr> <C-U> <SID>rubout_line()

function! s:ctrl_u()
  let pos = col('.')
  if pos > g:cur_col
    let @- = getline('.')[g:cur_col-1:pos-2]
  endif
  return "\<C-U>"
endfunction

inoremap <expr> <C-U> <SID>ctrl_u()

" delete to end of line
if get(g:, 'readline_ctrl_k', 1)
  cnoremap <expr> <C-K> <SID>delete_line()
endif

" transpose characters before cursor
cnoremap <expr> <C-T> <SID>transpose_chars()

" yank (paste) previously deleted text
cnoremap <expr> <C-Y> <SID>yank()

" open cmdline-window
cnoremap <c-x><c-e> <c-f>

"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
" mapping options
"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

" escape mappings
if get(g:, 'readline_esc', 0) || v:version <= 703
  cnoremap <Esc> <NOP>
else
  " emulate escape unless it was pressed using a modifier
  function! s:esc()
    if getchar(0)
      return ''
    endif
    return &cpoptions =~# 'x' ? '\<CR>' : '\<C-C>'
  endfunction
  cnoremap <nowait> <expr> <Esc> <SID>esc()
endif

" meta key mappings
if get(g:, 'readline_meta', 0) || has('nvim')
  cmap <M-B> <Esc>b
  cmap <M-B> <Esc>B
  cmap <M-F> <Esc>f
  cmap <M-F> <Esc>F
  cmap <M-BS> <Esc><BS>
  cmap <M-D> <Esc>d
  cmap <M-D> <Esc>D
  cmap <M-T> <Esc>t
  cmap <M-T> <Esc>T
  cmap <M-U> <Esc>u
  cmap <M-U> <Esc>U
  cmap <M-L> <Esc>l
  cmap <M-L> <Esc>L
  cmap <M-C> <Esc>c
  cmap <M-C> <Esc>C
  cmap <M-#> <Esc>#
  cmap <M-?> <Esc>?
  cmap <M-=> <Esc>=
  cmap <M-*> <Esc>*
  cmap <M-.> <Esc>.
  cmap <M-N> <Down>
  cmap <M-P> <Up>
endif

"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
" internal variables
"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

" [:alnum:] and [:alpha:] only matches ASCII characters.  But we can use the
" fact that [:upper:] and [:lower:] will match non-ASCII characters to create
" a pattern that will match alphanumeric characters from all encodings.
let s:wordchars = '[[:upper:][:lower:][:digit:]]'

" buffer to hold the previously deleted text
let s:yankbuf = ''

"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
" internal functions
"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

" get mapping to move one word forward
function! s:forward_word()
  let x = s:getcur()
  return " \b" . s:move_to(s:next_word(x), x)
endfunction

" get mapping to move one word back
function! s:back_word()
  let x = s:getcur()
  return " \b" . s:move_to(s:prev_word(x), x)
endfunction

" get mapping to rubout word behind cursor
function! s:rubout_word()
  let x = s:getcur()
  return s:delete_to(s:prev_word(x), x)
endfunction

" get mapping to rubout space delimited word behind of cursor
function! s:rubout_longword()
  let x = s:getcur()
  return s:delete_to(s:prev_longword(x), x)
endfunction

" get mapping to delete word in front of cursor
function! s:delete_word()
  let x = s:getcur()
  return s:delete_to(s:next_word(x), x)
endfunction

" get mapping to delete to end of line
function! s:delete_line()
  return s:delete_to(s:strlen(getcmdline()), s:getcur())
endfunction

" get mapping to rubout to start of line
function! s:rubout_line()
  return s:delete_to(0, s:getcur())
endfunction

" get mapping to make word uppercase
function! s:upcase_word()
  let x = s:getcur()
  let y = s:next_word(x)
  return repeat("\<Del>", y - x) . substitute(toupper(s:strpart(getcmdline(),
  \ x, y - x)), '[[:cntrl:]]', "\<C-V>&", 'g')
endfunction

" get mapping to make word lowercase
function! s:downcase_word()
  let x = s:getcur()
  let y = s:next_word(x)
  return repeat("\<Del>", y - x) . substitute(tolower(s:strpart(getcmdline(),
  \ x, y - x)), '[[:cntrl:]]', "\<C-V>&", 'g')
endfunction

" get mapping to make word capitalized
function! s:capitalize_word()
  let cmd = ""
  let s = getcmdline()
  let x = s:getcur()
  let y = s:next_word(x)
  while x < y
    let c = s:strpart(s, x, 1)
    let x += 1
    if c =~# s:wordchars
      let cmd .= "\<Del>" . toupper(s:strpart(s, x - 1, 1))
      break
    else
      let cmd .= "\<Right>"
    endif
  endwhile
  let cmd .= repeat("\<Del>", y - x) . substitute(tolower(s:strpart(
  \ getcmdline(), x, y - x)), '[[:cntrl:]]', "\<C-V>&", 'g')
  return " \b" . substitute(cmd, '[[:cntrl:]]', "\<C-V>&", 'g')
endfunction

function! s:last_cmd_word()
  let hist = histget(':', -1)
  return matchstr(hist, '\S\+$')
endfunction

" get mapping to yank (paste) the previously deleted text
function! s:yank()
  return substitute(s:yankbuf, '[[:cntrl:]]', "\<C-V>&", 'g')
endfunction

" get mapping to transpose chars before cursor position
function! s:transpose_chars()
  if !get(g:, 'readline_ctrl_t', 1) && &incsearch && getcmdtype() =~# '[/?]'
    return "\<C-T>"
  endif
  let s = getcmdline()
  let n = s:strlen(s)
  let x = s:getcur()
  if n < 2
    return ''
  endif
  let cmd = ''
  if x == n
    let cmd .= "\<Left>"
    let x -= 1
  endif
  return " \b" . cmd . "\b\<Right>" .
  \ substitute(s:strpart(s, x - 1, 1), '[[:cntrl:]]', "\<C-V>&", '')
endfunction

" get mapping to transpose words before cursor position
function! s:transpose_words()
  let s = getcmdline()
  let x = s:getcur()
  let end2 = s:next_word(x)
  let beg2 = s:prev_word(end2)
  let beg1 = s:prev_word(beg2)
  let end1 = s:next_word(beg1)
  if beg2 < end1
    return ''
  endif
  let str1 = s:strpart(s, beg1, end1 - beg1)
  let str2 = s:strpart(s, beg2, end2 - beg2)
  let len1 = s:strlen(str1)
  let len2 = s:strlen(str2)
  return " \b" . s:move_to(end2, x) . repeat("\b", len2) . str1 .
  \ s:move_to(end1, beg2 + len1) . repeat("\b", len1) .
  \ substitute(str2, '[[:cntrl:]]', "\<C-V>&", 'g') .
  \ s:move_to(end2, beg1 + len2)
endfunction

" Get mapping to move cursor to position.  Argument x is the position to move
" to.  Argument y is the current cursor position (note that this _must_ be in
" sync with the real cursor position).
function! s:move_to(x, y)
  if a:y < a:x
    return repeat("\<Right>", a:x - a:y)
  endif
  return repeat("\<Left>", a:y - a:x)
endfunction

" Get mapping to delete from cursor to position.  Argument x is the position
" to delete to.  Argument y represents the current cursor position (note that
" this _must_ be in sync with the real cursor position).
function! s:delete_to(x, y)
  if a:y == a:x
    return ''
  endif
  if a:y < a:x
    let s:yankbuf = s:strpart(getcmdline(), a:y, a:x - a:y)
    return repeat("\<Del>", a:x - a:y)
  endif
  let s:yankbuf = s:strpart(getcmdline(), a:x, a:y - a:x)
  return repeat("\b", a:y - a:x)
endfunction

" Get start position of previous word.  Argument x is the position to search
" from.
function! s:prev_word(x)
  let s = getcmdline()
  let x = a:x
  while x > 0 && s:strpart(s, x - 1, 1) !~# s:wordchars
    let x -= 1
  endwhile
  while x > 0 && s:strpart(s, x - 1, 1) =~# s:wordchars
    let x -= 1
  endwhile
  return x
endfunction

" Get start position of previous space delimited word.  Argument x is the
" position to search from.
function! s:prev_longword(x)
  let s = getcmdline()
  let x = a:x
  while x > 0 && s:strpart(s, x - 1, 1) !~# '\S'
    let x -= 1
  endwhile
  while x > 0 && s:strpart(s, x - 1, 1) =~# '\S'
    let x -= 1
  endwhile
  return x
endfunction

" Get end position of next word.  Argument x is the position to search from.
function! s:next_word(x)
  let s = getcmdline()
  let n = s:strlen(s)
  let x = a:x
  while x < n && s:strpart(s, x, 1) !~# s:wordchars
    let x += 1
  endwhile
  while x < n && s:strpart(s, x, 1) =~# s:wordchars
    let x += 1
  endwhile
  return x
endfunction

" Get the current cursor position on the edit line.  This differs from
" getcmdpos in that it counts chars instead of bytes and starts counting at 0.
function! s:getcur()
  return s:strlen((getcmdline() . ' ')[:getcmdpos() - 1]) - 1
endfunction

" for compatibility with earlier versions without strchars
if exists('*strchars')
  function! s:strlen(s)
    if v:version >= 800
      return strchars(a:s, 1)
    else
      return strchars(a:s)
    endif
  endfunction
else
  function! s:strlen(s)
    return strlen(a:s)
  endfunction
endif

" for compatibility with earlier versions without strcharpart
if exists('*strcharpart')
  function! s:strpart(s, n, m)
    return strcharpart(a:s, a:n, a:m)
  endfunction
else
  function! s:strpart(s, n, m)
    return strpart(a:s, a:n, a:m)
  endfunction
endif
