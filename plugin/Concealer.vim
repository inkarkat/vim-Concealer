" Concealer.vim: Manually conceal current word or selection.
"
" DEPENDENCIES:
"   - Requires Vim 7.3 or higher with the +conceal feature.
"   - ingo-library.vim plugin
"
" Copyright: (C) 2012-2021 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>

scriptencoding utf-8

" Avoid installing twice or when in unsupported Vim version.
if exists('g:loaded_Concealer') || (v:version < 703) || ! has('conceal')
    finish
endif
let g:loaded_Concealer = 1

"- configuration ---------------------------------------------------------------

if ! exists('g:Concealer_Characters_Global')
    if &encoding ==# 'utf-8'
	let g:Concealer_Characters_Global = '¹²³⁴⁵⁶⁷⁸⁹⁰ⁿ'
    else
	let g:Concealer_Characters_Global = '1234567890ñ'
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

command! -bang -count -nargs=* ConcealHere   if ! Concealer#Here(0, 1,    <bang>0, <count>, <q-args>) | echoerr ingo#err#Get() | endif
command!       -count -nargs=1 ConcealAdd    call Concealer#AddCommand(0,       1, <count>, <q-args>)
command! -bang -count -nargs=? ConcealRemove if ! Concealer#RemCommand(0, <bang>0, <count>, <q-args>) | echoerr ingo#err#Get() | endif
command! -bar Conceals call Concealer#List()


"- mappings --------------------------------------------------------------------

nnoremap <silent> <Plug>(ConcealerToggleLocal) :<C-u>call Concealer#ToggleLiteralHere(v:count, expand('<cword>'), 1)<CR>
if ! hasmapto('<Plug>(ConcealerToggleLocal)', 'n')
    nmap <Leader>XX <Plug>(ConcealerToggleLocal)
endif
vnoremap <silent> <Plug>(ConcealerToggleLocal) :<C-u>call Concealer#ToggleLiteralHere(v:count, ingo#selection#Get(), 0)<CR>
if ! hasmapto('<Plug>(Concealer)', 'x')
    xmap <Leader>XX <Plug>(ConcealerToggleLocal)
endif

nnoremap <silent> <Plug>(ConcealerAddGlobal) :<C-u>call Concealer#AddLiteralText(0, 1, v:count, expand('<cword>'), 1)<CR>
if ! hasmapto('<Plug>(ConcealerAddGlobal)', 'n')
    nmap <Leader>X+ <Plug>(ConcealerAddGlobal)
endif
vnoremap <silent> <Plug>(ConcealerAddGlobal) :<C-u>call Concealer#AddLiteralText(0, 1, v:count, ingo#selection#Get(), 0)<CR>
if ! hasmapto('<Plug>(Concealer)', 'x')
    xmap <Leader>X+ <Plug>(ConcealerAddGlobal)
endif
nnoremap <silent> <Plug>(ConcealerRemGlobal) :<C-u>call Concealer#RemLiteralText(0, v:count, expand('<cword>'), 1)<CR>
if ! hasmapto('<Plug>(ConcealerRemGlobal)', 'n')
    nmap <Leader>X- <Plug>(ConcealerRemGlobal)
endif
vnoremap <silent> <Plug>(ConcealerRemGlobal) :<C-u>call Concealer#RemLiteralText(0, v:count, ingo#selection#Get(), 0)<CR>
if ! hasmapto('<Plug>(Concealer)', 'x')
    xmap <Leader>X- <Plug>(ConcealerRemGlobal)
endif

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
