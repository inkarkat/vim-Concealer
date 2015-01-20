" Concealer.vim: Manually conceal current word or selection.
"
" DEPENDENCIES:
"   - ingo/avoidprompt.vim autoload script
"   - ingo/collections.vim autoload script
"   - ingo/dict/find.vim autoload script
"   - ingo/err.vim autoload script
"   - ingo/regexp.vim autoload script
"
" Copyright: (C) 2012-2014 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"   1.00.010	01-Jun-2014	Refactor listing of local conceals to use the
"				b:Concealer_Local values instead of parsing the
"				:syntax output.
"				Also make local conceals persist on syntax
"				changes by creating an analog
"				Concealer#UpdateLocalCount() and hooking it into
"				the autocmds, which are now also activated on
"				Concealer#AddLocal().
"				After a change of syntax, 'conceallevel' may
"				have been reset; trigger (now exposed)
"				Concealer#SetDefaults() on the Syntax event,
"				too.
"   1.00.009	29-May-2014	Implement toggling of {expr} without a passed
"				[count]: Determine the key by searching the
"				b:Concealer_Local for the a:pattern.
"				Rename Concealer#HereCommand() to
"				Concealer#Here().
"				Add Concealer#ToggleLiteralHere() for the
"				toggling-extended <Leader>XX mappings.
"				Also remove previous conceal on
"				:{count}ConcealHere {pattern}; there's no adding
"				to local groups, nowhere.
"   1.00.008	28-May-2014	:syn match doesn't support keepend.
"				Support extended :ConcealHere! via dedicated
"				Expose Concealer#AddLocal() and
"				Concealer#RemoveLocal() that also handle custom
"				a:char and non-numeric a:count => a:key.
"				Concealer#HereCommand().
"				Improve s:EchoConceal formatting.
"   1.00.007	05-May-2014	Abort :ConcealRemove on error.
"   1.00.006	14-Jun-2013	Minor: Make matchstr() robust against
"				'ignorecase'.
"   1.00.005	07-Jun-2013	Move EchoWithoutScrolling.vim into ingo-library.
"   1.00.004	24-May-2013	Move ingosearch.vim to ingo-library.
"   1.00.003	21-Feb-2013	Move ingocollections.vim to ingo-library.
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

" Use something like ingo#avoidprompt#EchoAsSingleLine() to emulate the built-in
" truncation of the search pattern (via ':set shortmess+=T').
function! s:Echo( msg, isShorten )
    echon (a:isShorten ? ingo#avoidprompt#Truncate(ingo#avoidprompt#TranslateLineBreaks(a:msg), 6) : a:msg)
endfunction

function! s:EchoConceal( data, isShorten )
    let [l:key, l:char, l:pattern] = a:data
    if l:key =~# '^\d\+$'
	echo printf('%3d    ', l:key)
    else
	echo printf('%-6s ', l:key)
    endif
    echohl Conceal
	echon (empty(l:char) ? ' ' : l:char)
    echohl None
    call s:Echo(printf("  %s", l:pattern), a:isShorten)
endfunction

function! s:GetLocalChar( key )
    if exists('b:Concealer_Local_Chars') && has_key(b:Concealer_Local_Chars, a:key)
	return b:Concealer_Local_Chars[a:key]
    else
	let l:index = a:key - 1
	return get(split(g:Concealer_Characters_Local, '\zs'), l:index, '')
    endif
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



function! Concealer#SetDefaults()
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
	noautocmd windo call Concealer#SetDefaults()
    execute l:currentWinNr . 'wincmd w'
    silent! execute l:originalWindowLayout
endfunction

function! s:Conceal( scope, key, char, pattern )
    execute printf('syntax match Concealer%s%s containedin=ALL transparent conceal %s /%s/',
    \   a:scope,
    \   a:key,
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

function! Concealer#UpdateLocalCount( key )
    silent! execute printf('syntax clear ConcealerLocal%s', a:key)

    let l:char = s:GetLocalChar(a:key)
    let l:pattern = get(b:Concealer_Local, a:key, '')
    call s:Conceal('Local', a:key, l:char, l:pattern)
endfunction
function! Concealer#UpdateCount( count )
    silent! execute printf('syntax clear ConcealerGlobal%d', a:count)

    let l:char = s:GetChar(a:count)
    for l:pattern in get(s:globalConceals, a:count, [])
	call s:Conceal('Global', a:count, l:char, l:pattern)
    endfor
endfunction
function! Concealer#UpdateBuffer( isUpdateLocal )
    for l:count in keys(s:globalConceals)
	call Concealer#UpdateCount(l:count)
    endfor

    if a:isUpdateLocal && exists('b:Concealer_Local')
	for l:count in keys(b:Concealer_Local)
	    call Concealer#UpdateLocalCount(l:count)
	endfor
    endif
endfunction
function! s:EnsureUpdates()
    if ! exists('#Concealer')
	augroup Concealer
	    autocmd!
	    autocmd BufWinEnter,Syntax * call Concealer#UpdateBuffer(1)
	    autocmd Syntax             * call Concealer#SetDefaults()
	    autocmd TabEnter * call Concealer#Winbufdo('call Concealer#UpdateBuffer(0)') | call Concealer#SetGlobalConcealDefaults()
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
	    if ! exists('b:Concealer_Local')
		let b:Concealer_Local = {}
		let l:count = 1
	    else
		let l:count = 1
		while has_key(b:Concealer_Local, l:count)
		    let l:count += 1
		endwhile
	    endif
	endif
	let l:char = get(split(g:Concealer_Characters_Local, '\zs'), l:count - 1, '')
	call Concealer#AddLocal(l:count, l:char, a:pattern)
	return [l:count, l:char, a:pattern]
    endif

endfunction
function! Concealer#AddLiteralText( isGlobal, count, text, isWholeWordSearch )
    let l:result = Concealer#AddPattern(a:isGlobal, a:count, ingo#regexp#FromLiteralText(a:text, a:isWholeWordSearch, '/'))

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
	    call Concealer#Winbufdo('call Concealer#UpdateBuffer(0)')
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
	let l:result = Concealer#RemPattern(a:count, ingo#regexp#FromLiteralText(a:text, a:isWholeWordSearch, '/'))
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
	call ingo#err#Set('Neither count nor pattern given (add ! to clear all conceals)')
	return 0
    endif

    let l:result = Concealer#RemPattern(a:count, a:pattern)
    if empty(l:result)
	call ingo#err#Set(empty(a:pattern) ?
	\   printf('No conceal %d defined', a:count) :
	\   (a:count ?
	\       printf('Pattern not found in %s', join(get(s:globalConceals, a:count, ['(empty conceal)']), '\|')) :
	\       'Pattern not found'
	\   )
	\)
	return 0
    else
	call s:EchoConceal(l:result, 0)
	return 1
    endif
endfunction

function! Concealer#AddLocal( key, char, pattern )
    if ! exists('b:Concealer_Local')
	let b:Concealer_Local = {}
    endif
    let b:Concealer_Local[a:key] = a:pattern

    call s:Conceal('Local', a:key, a:char, a:pattern)
    call Concealer#SetDefaults()
    call s:EnsureUpdates()
    return 1
endfunction
function! Concealer#RemoveLocal( key )
    silent! execute printf('syntax clear ConcealerLocal%s', a:key)
    silent! unlet! b:Concealer_Local[a:key]
    return 1
endfunction
function! Concealer#Here( isCommand, isBang, key, pattern, ... )
    if a:0
	" We need the custom (i.e. non-numeric) key -> char mapping to later
	" reinstate the syntax definitions, and for the :Conceals command.
	if ! exists('b:Concealer_Local_Chars')
	    let b:Concealer_Local_Chars = {}
	endif
	let b:Concealer_Local_Chars[a:key] = a:1
    endif

    if ! a:isBang
	call Concealer#RemoveLocal(a:key)
	if a:0
	    call Concealer#AddLocal(a:key, a:1, a:pattern)
	else
	    call Concealer#AddCommand(0, a:key, a:pattern)
	endif
	return 1
    else
	if empty(a:pattern)
	    if ! empty(a:key)
		if exists('b:Concealer_Local') && has_key(b:Concealer_Local, a:key)
		    return Concealer#RemoveLocal(a:key)
		else
		    call ingo#err#Set(printf('No local conceal %s defined', a:key))
		    return 0
		endif
	    elseif ! exists('b:Concealer_Local') || len(b:Concealer_Local) == 0
		call ingo#err#Set('No local conceals defined')
		return 0
	    else
		" Remove all local conceals.
		silent! execute 'syntax clear' join(map(keys(b:Concealer_Local), '"ConcealerLocal" . v:val'))
		let b:Concealer_Local = {}
		return 1
	    endif
	else
	    if empty(a:key) && exists('b:Concealer_Local')
		let l:key = ingo#dict#find#FirstKey(b:Concealer_Local, a:pattern, 'ingo#collections#numsort')
		if ! empty(l:key)
		    call Concealer#RemoveLocal(l:key)
		    call s:Echo(printf('No conceal of pattern %s', a:pattern), 1)
		    return 2
		endif
	    endif

	    if exists('b:Concealer_Local') && has_key(b:Concealer_Local, a:key)
		if b:Concealer_Local[a:key] ==# a:pattern
		    call Concealer#RemoveLocal(a:key)
		    call s:Echo(printf('No conceal of pattern %s', a:pattern), 1)
		    return 2
		elseif a:isCommand
		    call ingo#err#Set(printf('Passed pattern "%s" does not match existing definition "%s"', a:pattern, b:Concealer_Local[a:key]))
		    return 0
		else
		    call Concealer#RemoveLocal(a:key)
		endif
	    endif

	    if a:0
		call Concealer#AddLocal(a:key, a:1, a:pattern)
		call s:EchoConceal([a:key, a:1, a:pattern], ! a:isCommand)
	    else
		let l:result = Concealer#AddPattern(0, a:key, a:pattern)
		call s:EchoConceal(l:result, ! a:isCommand)
	    endif
	    return 1
	endif
    endif
endfunction
function! Concealer#ToggleLiteralHere( count, text, isWholeWordSearch )
    if empty(a:text)
	execute "normal! \<C-\>\<C-n>\<Esc>" | " Beep.
	return
    endif
    call Concealer#Here(0, 1, a:count, ingo#regexp#FromLiteralText(a:text, a:isWholeWordSearch, '/'))
endfunction



function! Concealer#ListLocal()
    if ! exists('b:Concealer_Local') || len(b:Concealer_Local) == 0
	return 0
    endif

    echohl Title
    echo 'cnt  char pattern (buffer-local)'
    echohl None

    for l:key in sort(keys(b:Concealer_Local), 'ingo#collections#numsort')
	call s:EchoConceal([l:key, s:GetLocalChar(l:key), b:Concealer_Local[l:key]], 0)
    endfor

    return 1
endfunction
function! Concealer#ListGlobal()
    echohl Title
    echo 'cnt  char pattern'
    echohl None

    for l:count in sort(ingo#collections#Unique(range(1, s:GetCharSize()) + keys(s:globalConceals)), 'ingo#collections#numsort')
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
