syntax on
set noswapfile

nmap <c-s> :x!<cr>
nmap <c-c> :qa!<cr>

imap <c-s> <esc>:x!<cr>
imap <c-c> <esc>:qa!<cr>
"so ~/.config/nvim_pure/theme.vim

augroup terraform_state_filetype
  autocmd!
  autocmd BufRead,BufNewFile *.tfstate setfiletype json
augroup END
