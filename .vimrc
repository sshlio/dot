"v11
syntax on
set ttyfast
set ttyscroll=3
set noswapfile
set number relativenumber
set signcolumn=yes
set cursorline cursorlineopt=number
set laststatus=2
set cmdwinheight=20
set autoindent
set tabstop=2 shiftwidth=2 softtabstop=2 expandtab
set nowrap
set title
set titlestring=%{fnamemodify(getcwd(),':t')}
set scrolloff=10
set sidescrolloff=10

if has('termguicolors')
  set termguicolors
endif

let &t_SI = "\<Esc>[6 q"
let &t_EI = "\<Esc>[2 q"

nnoremap <c-s> <c-x>
nnoremap sQ :qa!<cr>

noremap p "+p
noremap P "+P
xnoremap p "+p
xnoremap P "+P


cnoremap <c-v> <c-r>+
nnoremap <c-v> <c-w>o<c-w>v<c-w>L
nnoremap <c-w> :hide<cr>
nnoremap sw <c-w>
nnoremap <left> <c-w>h
nnoremap <right> <c-w>l
nnoremap G Gzz

function! StatuslineMode() abort
  if win_getid() != str2nr(get(g:, 'actual_curwin', string(win_getid())))
    return ' ------ '
  endif

  let l:mode = mode()
  return get({
        \ 'n': ' NORMAL ',
        \ 'i': ' INSERT ',
        \ 'v': ' VISUAL ',
        \ 'V': ' V-LINE ',
        \ "\<C-v>": ' V-BLOCK ',
        \ 'R': ' REPLACE ',
        \ 'c': ' COMMAND ',
        \ 's': ' SELECT ',
        \ 'S': ' S-LINE ',
        \ "\<C-s>": ' S-BLOCK ',
        \ 't': ' TERM ',
        \ '!': ' SHELL ',
        \ 'r': ' PROMPT ',
        \ }, l:mode, ' ' . toupper(l:mode) . ' ')
endfunction

let s:terminal_buffer = -1

function! s:open_terminal_popup() abort
  let l:width = &columns
  let l:height = (&lines - &cmdheight) * 9 / 10

  let s:terminal_buffer = term_start(&shell, #{hidden: 1, term_finish: 'close'})
  let l:popup = popup_create(s:terminal_buffer, #{pos: 'botleft', line: &lines - &cmdheight, col: 1, posinvert: 0, fixed: 1, minwidth: l:width, maxwidth: l:width, minheight: l:height, maxheight: l:height, border: [1, 0, 0, 0], highlight: 'Normal'})

  call win_execute(l:popup, 'setlocal number relativenumber')
endfunction

function! s:close_terminal_popup() abort
  call popup_close(win_getid())
endfunction

nnoremap <silent> <c-p> :call <sid>open_terminal_popup()<cr>
tnoremap <silent> <c-w> <c-w>:call <sid>close_terminal_popup()<cr>
tnoremap <c-e> <c-w>N

xnoremap v V
nnoremap V v$h
nnoremap Y y$
nnoremap so <Cmd>so %<cr>
nnoremap sd "fyy"fp

"colorscheme desert
colorscheme habamax

highlight StatusLineMode guifg=#1c1c1c guibg=#aaaaaa gui=bold ctermfg=234 ctermbg=248 cterm=bold
set statusline=\ %#StatusLineMode#%{StatuslineMode()}%*\ %f%m%r%=%l:%c\ %p%%

highlight LineNr guifg=#666666
highlight CursorLineNr guifg=#aaaaaa
highlight SignColumn term=NONE cterm=NONE gui=NONE guibg=NONE ctermbg=NONE
highlight WinSeparator guifg=NONE guibg=NONE ctermfg=NONE ctermbg=NONE
highlight VertSplit guifg=NONE guibg=NONE ctermfg=NONE ctermbg=NONE

highlight NonText guibg=#2a2a2a guifg=#444444
highlight! link EndOfBuffer NonText
highlight VertSplit guifg=#777777

set fillchars=vert:│

augroup terraform_state_filetype
  autocmd!
  autocmd BufRead,BufNewFile *.tfstate setfiletype json
  autocmd BufRead,BufNewFile *.vimrc set commentstring=\"\ %s
  autocmd BufRead,BufNewFile *.vim set commentstring=\"\ %s

  autocmd TextYankPost * if v:event.operator ==# 'y' && empty(v:event.regname) | call setreg('+', v:event.regcontents, v:event.regtype) | endif
augroup END

sign define ErrorSign text=✘ texthl=Error

"function! Tapi_Msg(buf, msg)
"  echom 'terminal says: ' . a:msg
"endfunction

"#printf '\033]51;["call","Tapi_Msg","hello from shell"]\007'

set termguicolors

function! CommentExpr()
  let c = substitute(&commentstring, '%s.*$', '', '')

  return getline('.') =~# '^\s*' . escape(c, '\.^$~[]*')
        \ ? '^' . strlen(c) . 'x'
        \ : 'I' . c . "\<Esc>"
endfunction

nnoremap <expr> <c-c> CommentExpr()
