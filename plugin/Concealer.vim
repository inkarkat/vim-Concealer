" Concealer.vim: Manually conceal current word or selection.
"
" DEPENDENCIES:
"   - Requires Vim 7.0 or higher.
"   - ingointegration.vim autoload script
"   - Concealer.vim autoload script
"
" Copyright: (C) 2012 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"	001	24-Jul-2012	file creation

scriptencoding utf-8

" Avoid installing twice or when in unsupported Vim version.
if exists('g:loaded_Concealer') || (v:version < 700)
    finish
endif
let g:loaded_Concealer = 1

"- configuration ---------------------------------------------------------------

if ! exists('g:Concealer_Characters')
    if &encoding ==# 'utf-8'
	let g:Concealer_Characters = '¹²³£¥§¤®ÞØ×'
    else
	let g:Concealer_Characters = '1234567890X'
    endif
endif
if ! exists('g:Concealer_ConcealLevel')
    let g:Concealer_ConcealLevel = 2
endif
if ! exists('g:Concealer_ConcealCursor')
    let g:Concealer_ConcealCursor = 'n'
endif


"- commands --------------------------------------------------------------------

command! -count -nargs=1 -complete=expression Conceal call Concealer#AddPattern(<count>, <q-args>)


"- mappings --------------------------------------------------------------------

nnoremap <silent> <Plug>(ConcealerAdd) :<C-u>call Concealer#AddLiteralText(v:count, expand('<cword>'), 1)<CR>
if ! hasmapto('<Plug>(ConcealerAdd)', 'n')
    nmap <Leader>XX <Plug>(ConcealerAdd)
endif
vnoremap <silent> <Plug>(ConcealerAdd) :<C-u>call Concealer#AddLiteralText(v:count, ingointegration#GetVisualSelection(), 0)<CR>
if ! hasmapto('<Plug>(Concealer)', 'x')
    xmap <Leader>XX <Plug>(ConcealerAdd)
endif

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
