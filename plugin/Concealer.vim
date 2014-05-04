" Concealer.vim: Manually conceal current word or selection.
"
" DEPENDENCIES:
"   - Requires Vim 7.3 or higher with the +conceal feature.
"   - ingo/selection.vim autoload script
"   - Concealer.vim autoload script
"
" Copyright: (C) 2012-2013 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"   1.00.004	24-May-2013	Move ingointegration#GetVisualSelection() into
"				ingo-library.
"   1.00.003	05-Nov-2012	Remove -complete=expression; it's not useful for
"				completing regexp patterns.
"   1.00.002	25-Jul-2012	Add mappings and commands for conceal group
"				removal.
"				Add :Conceals command.
"				Correct inclusion guard.
"	001	24-Jul-2012	file creation

scriptencoding utf-8

" Avoid installing twice or when in unsupported Vim version.
if exists('g:loaded_Concealer') || (v:version < 703) || ! has('conceal')
    finish
endif
let g:loaded_Concealer = 1

"- configuration ---------------------------------------------------------------

if ! exists('g:Concealer_Characters_Global')
    if &encoding ==# 'utf-8'
	let g:Concealer_Characters_Global = '¹²³£¥§¤®ÞØ×'
    else
	let g:Concealer_Characters_Global = '1234567890X'
    endif
endif
if ! exists('g:Concealer_Characters_Local')
    if &encoding ==# 'utf-8'
	let g:Concealer_Characters_Local = 'ÅßÇÐËµðãøº'
    else
	let g:Concealer_Characters_Local = 'ABCDEFGHo*'
    endif
endif

if ! exists('g:Concealer_ConcealLevel')
    let g:Concealer_ConcealLevel = 2
endif
if ! exists('g:Concealer_ConcealCursor')
    let g:Concealer_ConcealCursor = 'n'
endif


"- commands --------------------------------------------------------------------

command!       -count -nargs=1 ConcealHere   call Concealer#AddCommand(      0, <count>, <q-args>)
command!       -count -nargs=1 ConcealAdd    call Concealer#AddCommand(      1, <count>, <q-args>)
command! -bang -count -nargs=? ConcealRemove call Concealer#RemCommand(<bang>0, <count>, <q-args>)
command! -bar Conceals call Concealer#List()


"- mappings --------------------------------------------------------------------

nnoremap <silent> <Plug>(ConcealerAddLocal) :<C-u>call Concealer#AddLiteralText(0, v:count, expand('<cword>'), 1)<CR>
if ! hasmapto('<Plug>(ConcealerAddLocal)', 'n')
    nmap <Leader>XX <Plug>(ConcealerAddLocal)
endif
vnoremap <silent> <Plug>(ConcealerAddLocal) :<C-u>call Concealer#AddLiteralText(0, v:count, ingo#selection#Get(), 0)<CR>
if ! hasmapto('<Plug>(Concealer)', 'x')
    xmap <Leader>XX <Plug>(ConcealerAddLocal)
endif
nnoremap <silent> <Plug>(ConcealerAddGlobal) :<C-u>call Concealer#AddLiteralText(1, v:count, expand('<cword>'), 1)<CR>
if ! hasmapto('<Plug>(ConcealerAddGlobal)', 'n')
    nmap <Leader>X+ <Plug>(ConcealerAddGlobal)
endif
vnoremap <silent> <Plug>(ConcealerAddGlobal) :<C-u>call Concealer#AddLiteralText(1, v:count, ingo#selection#Get(), 0)<CR>
if ! hasmapto('<Plug>(Concealer)', 'x')
    xmap <Leader>X+ <Plug>(ConcealerAddGlobal)
endif
nnoremap <silent> <Plug>(ConcealerRemGlobal) :<C-u>call Concealer#RemLiteralText(v:count, expand('<cword>'), 1)<CR>
if ! hasmapto('<Plug>(ConcealerRemGlobal)', 'n')
    nmap <Leader>X- <Plug>(ConcealerRemGlobal)
endif
vnoremap <silent> <Plug>(ConcealerRemGlobal) :<C-u>call Concealer#RemLiteralText(v:count, ingo#selection#Get(), 0)<CR>
if ! hasmapto('<Plug>(Concealer)', 'x')
    xmap <Leader>X- <Plug>(ConcealerRemGlobal)
endif

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
