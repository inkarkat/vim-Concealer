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


function! s:SetConcealDefaults()
    if ! empty(g:Concealer_ConcealLevel)
	let &l:conceallevel = g:Concealer_ConcealLevel
    endif
    if ! empty(g:Concealer_ConcealCursor)
	let &l:concealcursor = g:Concealer_ConcealCursor
    endif
endfunction

function! s:Conceal( count, char, pattern )
    execute printf('syntax match Concealer%d containedin=ALL transparent conceal %s /%s/',
    \   a:count,
    \   (empty(a:char) ? '' : 'cchar=' . a:char),
    \   a:pattern
    \)

    call s:SetConcealDefaults()
endfunction
function! Concealer#AddPattern( count, pattern )
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

    let l:char = get(split(g:Concealer_Characters, '\zs'), l:count - 1, '')

    call s:Conceal(l:count, l:char, a:pattern)

    return l:char
endfunction
function! Concealer#AddLiteralText( count, text, isWholeWordSearch )
    let l:char = Concealer#AddPattern(a:count, ingosearch#LiteralTextToSearchPattern(a:text, a:isWholeWordSearch, '/'))

    echo
    echohl Conceal
	echon l:char
    echohl None
    echon '='
    call s:Echo(a:text)
endfunction

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
