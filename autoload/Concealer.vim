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
"   1.00.002	25-Jul-2012	Add dedicated functions to back up the commands,
"				so that error messages are printed.
"				Add Concealer#List() and implement this for both
"				global and local conceal groups (in different
"				ways, due to the ways they are stored).
"				Adapt s:SetConcealDefaults() to work on global
"				conceal groups: Invoking on the first window of
"				each buffer isn't sufficient, as it sets
"				window-scoped stuff. Rather, apply once for
"				local conceal groups, and for each window
"				(repeated once when each tab page is entered)
"				for global conceal groups.
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
	echon (empty(l:char) ? ' ' : l:char)
    echohl None
    call s:Echo(printf(' %s', l:pattern), a:isShorten)
endfunction

function! s:GetLocalChar( count )
    return get(split(g:Concealer_Characters_Local, '\zs'), a:count - 1, '')
endfunction
function! s:GetChar( count )
    return get(split(g:Concealer_Characters_Global, '\zs'), a:count - 1, '')
endfunction
function! s:GetCharSize()
    return len(split(g:Concealer_Characters_Global, '\zs'))
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



function! s:SetDefaults()
    if ! empty(g:Concealer_ConcealLevel)
	let &conceallevel = g:Concealer_ConcealLevel
    endif
    if ! empty(g:Concealer_ConcealCursor)
	let &concealcursor = g:Concealer_ConcealCursor
    endif
endfunction
function! Concealer#SetGlobalConcealDefaults()
    if exists('t:Concealer_DidDefaults')
	return
    endif
    let t:Concealer_DidDefaults = 1

    if empty(g:Concealer_ConcealLevel) && empty(g:Concealer_ConcealCursor)
	return
    endif

    " Change both global and local settings, so that new buffers in that window
    " and new windows inherit the settings.
    " The global settting cannot be changed via setwinvar(), so we have to
    " iterate through them.

    let l:currentWinNr = winnr()
    " By entering a window, its height is potentially increased from 0 to 1 (the
    " minimum for the current window). To avoid any modification, save the window
    " sizes and restore them after visiting all windows.
    let l:originalWindowLayout = winrestcmd()
	noautocmd windo call s:SetDefaults()
    execute l:currentWinNr . 'wincmd w'
    silent! execute l:originalWindowLayout
endfunction

function! s:Conceal( scope, count, char, pattern )
    execute printf('syntax match Concealer%s%d containedin=ALL transparent keepend conceal %s /%s/',
    \   a:scope,
    \   a:count,
    \   (empty(a:char) ? '' : 'cchar=' . a:char),
    \   a:pattern
    \)
endfunction



if ! exists('s:globalCount')
    let s:globalCount = 1
    let s:globalConceals = {}
endif
function! s:Cycle()
    let l:charNum = s:GetCharSize()
    let l:startCount = (s:globalCount <= l:charNum ? s:globalCount : 1)
    for l:idx in range(l:charNum)
	let l:newCount = l:startCount + l:idx
	if empty(get(s:globalConceals, ((l:newCount - 1) % l:charNum) + 1, []))
	    if s:globalCount < l:newCount
		let s:globalCount = l:newCount
	    endif
	    return l:newCount
	endif
    endfor

    let s:globalCount += 1
    return s:globalCount
endfunction

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
	    autocmd BufWinEnter,Syntax * call Concealer#UpdateBuffer()
	    autocmd TabEnter * call Concealer#Winbufdo('call Concealer#UpdateBuffer()') | call Concealer#SetGlobalConcealDefaults()
	augroup END
    endif
endfunction
function! Concealer#AddPattern( isGlobal, count, pattern )
    if a:isGlobal
	if a:count
	    let l:count = a:count
	else
	    let l:count = s:Cycle()
	endif

	if has_key(s:globalConceals, l:count)
	    if index(s:globalConceals[l:count], a:pattern) == -1
		call add(s:globalConceals[l:count], a:pattern)
	    endif
	else
	    let s:globalConceals[l:count] = [a:pattern]
	endif

	call Concealer#Winbufdo(printf('call Concealer#UpdateCount(%d)', l:count))
	call Concealer#SetGlobalConcealDefaults()
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
	call s:SetDefaults()
	return [l:count, l:char, a:pattern]
    endif

endfunction
function! Concealer#AddLiteralText( isGlobal, count, text, isWholeWordSearch )
    let l:result = Concealer#AddPattern(a:isGlobal, a:count, ingosearch#LiteralTextToSearchPattern(a:text, a:isWholeWordSearch, '/'))

    call s:EchoConceal(l:result, 1)
endfunction

function! Concealer#RemPattern( count, pattern )
    if a:count
	if ! has_key(s:globalConceals, a:count)
	    return []
	endif
	let l:counts = [a:count]
    else
	if empty(a:pattern)
	    " Specialization: Just trash everything.
	    for l:count in keys(s:globalConceals)
		" First clear the patterns only, so that
		" Concealer#UpdateBuffer() still iterates over the counts to
		" remove the syntax definitions.
		let s:globalConceals[l:count] = []
	    endfor
	    call Concealer#Winbufdo('call Concealer#UpdateBuffer()')
	    " Now we can clear the entire dictionary.
	    let s:globalConceals = {}
	    return [0, ' ', '']
	else
	    let l:counts = keys(s:globalConceals)
	endif
    endif

    for l:count in l:counts
	if empty(a:pattern)
	    unlet! s:globalConceals[l:count]
	else
	    let l:prevLen = len(s:globalConceals[l:count])
	    call filter(s:globalConceals[l:count], 'v:val !=# a:pattern')
	    if len(s:globalConceals[l:count]) == l:prevLen
		" The pattern wasn't in that slot.
		continue
	    endif
	endif

	call Concealer#Winbufdo(printf('call Concealer#UpdateCount(%d)', l:count))
	return [l:count, s:GetChar(l:count), join(get(s:globalConceals, l:count, []), '\|')]
    endfor

    return []
endfunction
function! Concealer#RemLiteralText( count, text, isWholeWordSearch )
    if a:count
	let l:result = Concealer#RemPattern(a:count, '')
    else
	let l:result = Concealer#RemPattern(a:count, ingosearch#LiteralTextToSearchPattern(a:text, a:isWholeWordSearch, '/'))
    endif
    if empty(l:result)
	" The text wasn't found; inform the user via a bell.
	execute "normal! \<C-\>\<C-n>\<Esc>"
    else
	call s:EchoConceal(l:result, 1)
    endif
endfunction

function! Concealer#AddCommand( isGlobal, count, pattern )
    let l:result = Concealer#AddPattern(a:isGlobal, a:count, a:pattern)
    call s:EchoConceal(l:result, 0)
endfunction
function! Concealer#RemCommand( isForce, count, pattern )
    if ! a:count && empty(a:pattern) && ! a:isForce
	call s:ErrorMsg('Neither count nor pattern given (add ! to clear all conceals)')
	return
    endif

    let l:result = Concealer#RemPattern(a:count, a:pattern)
    if empty(l:result)
	call s:ErrorMsg(empty(a:pattern) ?
	\   printf('No conceal %d defined', a:count) :
	\   (a:count ?
	\       printf('Pattern not found in %s', join(get(s:globalConceals, a:count, ['(empty conceal)']), '\|')) :
	\       'Pattern not found'
	\   )
	\)
    else
	call s:EchoConceal(l:result, 0)
    endif
endfunction

function! s:ParseSyntaxOutput( syntaxLine )
    return matchlist(a:syntaxLine, '^\%(ConcealerLocal\(\d\+\)\s.\{-}\)\?\s\+match /\(.*\)/')[1:2]
endfunction
function! Concealer#ListLocal()
    if ! exists('b:Concealer_Count') || b:Concealer_Count == 0
	return 0
    endif

    redir => l:concealSyntaxOutput
    silent! execute 'syntax list' join(map(range(1, b:Concealer_Count), '"ConcealerLocal" . v:val'))
    redir END
    let l:concealSyntax = split(l:concealSyntaxOutput, "\n")[1:]
    if empty(l:concealSyntax)
	return 0
    endif

    echohl Title
    echo 'cnt char  pattern (buffer-local)'
    echohl None

    let l:prevCount = 0
    let l:patterns = []
    for l:line in l:concealSyntax
	let [l:count, l:pattern] = s:ParseSyntaxOutput(l:line)
	if empty(l:count)
	    let l:count = l:prevCount
	    call add(l:patterns, l:pattern)
	else
	    if l:prevCount > 0
		call s:EchoConceal([l:prevCount, s:GetLocalChar(l:prevCount), join(l:patterns, '\|')], 1)
	    endif
	    let l:prevCount = l:count
	    let l:patterns = [l:pattern]
	endif
    endfor
    if l:prevCount > 0
	call s:EchoConceal([l:prevCount, s:GetLocalChar(l:prevCount), join(l:patterns, '\|')], 1)
    endif

    return 1
endfunction
function! Concealer#ListGlobal()
    echohl Title
    echo 'cnt char  pattern'
    echohl None

    for l:count in sort(ingocollections#unique(range(1, s:GetCharSize()) + keys(s:globalConceals)), 'ingocollections#numsort')
	call s:EchoConceal([l:count, s:GetChar(l:count), join(get(s:globalConceals, l:count, []), '\|')], 0)
    endfor
endfunction
function! Concealer#List()
    let l:hasLocal = Concealer#ListLocal()
    if ! l:hasLocal || ! empty(keys(s:globalConceals))
	" Do not show the empty global conceals when local conceals are defined;
	" it's unlikely that one is using both local and global concurrently, so
	" let's focus the output on the currently active set.
	call Concealer#ListGlobal()
    endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
