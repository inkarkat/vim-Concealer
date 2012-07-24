" Concealer.vim: Manually conceal current word or selection.
"
" DEPENDENCIES:
"   - ingosearch.vim autoload script.
"   - EchoWithoutScrolling.vim (optional).
"
" Copyright: (C) 2012 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"	001	24-Jul-2012	file creation

" Use EchoWithoutScrolling#Echo to emulate the built-in truncation of the search
" pattern (via ':set shortmess+=T').
silent! call EchoWithoutScrolling#MaxLength()	" Execute a function to force autoload.
if exists('*EchoWithoutScrolling#Echo')
    function! s:Echo( msg )
	echon EchoWithoutScrolling#Truncate(EchoWithoutScrolling#TranslateLineBreaks(a:msg), 2)
    endfunction
else " fallback
    function! s:Echo( msg )
	execute 'echon' a:msg
    endfunction
endif

function! Concealer#Winbufdo( command )
    let l:buffers = []

    let l:currentWinNr = winnr()
    " By entering a window, its height is potentially increased from 0 to 1 (the
    " minimum for the current window). To avoid any modification, save the window
    " sizes and restore them after visiting all windows.
    let l:originalWindowLayout = winrestcmd()
	noautocmd windo
	    \   if index(l:buffers, bufnr('')) == -1 |
	    \       call add(l:buffers, bufnr('')) |
	    \       execute a:command |
	    \   endif
    execute l:currentWinNr . 'wincmd w'
    silent! execute l:originalWindowLayout
endfunction


function! s:SetConcealDefaults()
    if ! empty(g:Concealer_ConcealLevel)
	let &l:conceallevel = g:Concealer_ConcealLevel
    endif
    if ! empty(g:Concealer_ConcealCursor)
	let &l:concealcursor = g:Concealer_ConcealCursor
    endif
endfunction

function! s:Conceal( scope, count, char, pattern )
    execute printf('syntax match Concealer%s%d containedin=ALL transparent keepend conceal %s /%s/',
    \   a:scope,
    \   a:count,
    \   (empty(a:char) ? '' : 'cchar=' . a:char),
    \   a:pattern
    \)

    call s:SetConcealDefaults()
endfunction
let s:globalCount = 0
let s:globalConceals = {}
function! Concealer#UpdateCount( count )
    silent! execute printf('syntax clear ConcealerGlobal%d', a:count)

    let l:char = get(split(g:Concealer_Characters_Global, '\zs'), a:count - 1, '')
    for l:pattern in get(s:globalConceals, a:count, [])
	call s:Conceal('Global', a:count, l:char, l:pattern)
    endfor
endfunction
function! Concealer#UpdateBuffer()
    for l:count in keys(s:globalConceals)
	call Concealer#UpdateCount(l:count)
    endfor
endfunction
function! s:EnsureUpdates()
    if ! exists('#Concealer')
	augroup Concealer
	    autocmd!
	    autocmd BufWinEnter * call Concealer#UpdateBuffer()
	    autocmd TabEnter    * call Concealer#Winbufdo('call Concealer#UpdateBuffer()')
	augroup END
    endif
endfunction
function! Concealer#AddPattern( isGlobal, count, pattern )
    if a:isGlobal
	if a:count
	    let l:count = a:count
	else
	    let s:globalCount += 1
	    let l:count = s:globalCount
	endif

	if has_key(s:globalConceals, l:count)
	    if index(s:globalConceals[l:count], a:pattern) == -1
		call add(s:globalConceals[l:count], a:pattern)
	    endif
	else
	    let s:globalConceals[l:count] = [a:pattern]
	endif

	call Concealer#Winbufdo(printf('call Concealer#UpdateCount(%d)', l:count))
	call s:EnsureUpdates()

	let l:char = get(split(g:Concealer_Characters_Global, '\zs'), l:count - 1, '')
	return [l:char, join(s:globalConceals[l:count], '\|')]
    else
	if a:count
	    let l:count = a:count
	else
	    if exists('b:Concealer_Count')
		let b:Concealer_Count += 1
	    else
		let b:Concealer_Count = 1
	    endif
	    let l:count = b:Concealer_Count
	endif
	let l:char = get(split(g:Concealer_Characters_Local, '\zs'), l:count - 1, '')

	call s:Conceal('Local', l:count, l:char, a:pattern)
	return [l:char, a:pattern]
    endif

endfunction
function! Concealer#AddLiteralText( isGlobal, count, text, isWholeWordSearch )
    let [l:char, l:pattern] = Concealer#AddPattern(a:isGlobal, a:count, ingosearch#LiteralTextToSearchPattern(a:text, a:isWholeWordSearch, '/'))

    echo
    echohl Conceal
	echon l:char
    echohl None
    echon '='
    call s:Echo(printf('/%s/', l:pattern))
endfunction

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
