" Concealer.vim: Manually conceal current word or selection.
"
" DEPENDENCIES:
"   - ingocollections.vim autoload script
"   - ingosearch.vim autoload script
"   - EchoWithoutScrolling.vim (optional)
"
" Copyright: (C) 2012 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"	001	24-Jul-2012	file creation
let s:save_cpo = &cpo
set cpo&vim

" Use EchoWithoutScrolling#Echo to emulate the built-in truncation of the search
" pattern (via ':set shortmess+=T').
silent! call EchoWithoutScrolling#MaxLength()	" Execute a function to force autoload.
if exists('*EchoWithoutScrolling#Echo')
    function! s:Echo( msg, isShorten )
	echon (a:isShorten ? EchoWithoutScrolling#Truncate(EchoWithoutScrolling#TranslateLineBreaks(a:msg), 6) : a:msg)
    endfunction
else " fallback
    function! s:Echo( msg, isShorten )
	echon a:msg
    endfunction
endif

function! s:ErrorMsg( text )
    echohl ErrorMsg
    let v:errmsg = a:text
    echomsg v:errmsg
    echohl None
endfunction

function! s:EchoConceal( data, isShorten )
    let [l:count, l:char, l:pattern] = a:data
    echo printf('%3d ', l:count)
    echohl Conceal
	echon l:char
    echohl None
    call s:Echo(printf(' %s', l:pattern), a:isShorten)
endfunction

function! s:GetChar( count )
    return get(split(g:Concealer_Characters_Global, '\zs'), a:count - 1, '')
endfunction

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

    let l:char = s:GetChar(a:count)
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

	return [l:count, s:GetChar(l:count), join(s:globalConceals[l:count], '\|')]
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
	return [l:count, l:char, a:pattern]
    endif

endfunction
function! Concealer#AddLiteralText( isGlobal, count, text, isWholeWordSearch )
    let l:result = Concealer#AddPattern(a:isGlobal, a:count, ingosearch#LiteralTextToSearchPattern(a:text, a:isWholeWordSearch, '/'))

    call s:EchoConceal(l:result, 1)
endfunction

function! Concealer#RemPattern( count, pattern )
    if ! has_key(s:globalConceals, a:count)
	return []
    endif

    if empty(a:pattern)
	unlet! s:globalConceals[a:count]
    else
	let l:prevLen = len(s:globalConceals[a:count])
	call filter(s:globalConceals[a:count], 'v:val !=# a:pattern')
	if len(s:globalConceals[a:count]) == l:prevLen
	    return []
	endif
    endif

    call Concealer#Winbufdo(printf('call Concealer#UpdateCount(%d)', a:count))
    return [a:count, s:GetChar(a:count), join(get(s:globalConceals, a:count, []), '\|')]
endfunction
function! Concealer#RemLiteralText( count, text, isWholeWordSearch )
    let l:result = Concealer#RemPattern(a:count, ingosearch#LiteralTextToSearchPattern(a:text, a:isWholeWordSearch, '/'))
    if empty(l:result)
	" The text wasn't found in the search pattern; inform the user via a
	" bell.
	execute "normal! \<C-\>\<C-n>\<Esc>"
    else
	call s:EchoConceal(l:result, 1)
    endif
endfunction

function! Concealer#AddCommand( isGlobal, count, pattern )
    let l:result = Concealer#AddPattern(a:isGlobal, a:count, a:pattern)
    call s:EchoConceal(l:result, 0)
endfunction
function! Concealer#RemCommand( count, pattern )
    let l:result = Concealer#RemPattern(a:count, a:pattern)
    if empty(l:result)
	call s:ErrorMsg(empty(a:pattern) ?
	\   printf('No conceal %d defined', a:count) :
	\   printf('Pattern not found in %s', join(get(s:globalConceals, a:count, ['(empty conceal)']), '\|'))
	\)
    else
	call s:EchoConceal(l:result, 0)
    endif
endfunction

function! Concealer#List()
    echohl Title
    echo 'cnt char pattern'
    echohl None

    let l:chars = split(g:Concealer_Characters_Global, '\zs')
    for l:count in sort(ingocollections#unique(range(1, len(l:chars)) + keys(s:globalConceals)), 'ingocollections#numsort')
	call s:EchoConceal([l:count, s:GetChar(l:count), join(get(s:globalConceals, l:count, []), '\|')], 0)
    endfor
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
