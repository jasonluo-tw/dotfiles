set mouse=c     " Not to use mouse
set pastetoggle=<F10>
set nocompatible              " be iMproved, required
"filetype off                  " required
filetype plugin on
let g:polyglot_disabled = ['csv']

" for last-position-jump
autocmd BufReadPost * if @% !~# '\.git[\/\\]COMMIT_EDITMSG$' && line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g`\"" | endif 

" Vista.vim {{{
let g:vista_default_executive = 'nvim_lsp'
let g:vista#renderer#enable_icon = 0
let g:vista_no_mappings = 1
let g:vista_icon_indent = ["╰─▸ ", "├─▸ "]
let g:vista_echo_cursor_strategy = "both"

nnoremap <localLeader>t <cmd>Vista!!<CR>
nmap <F6> :Vista!!<CR>
" }}}

" snipet
let g:UltiSnipsExpandTrigger="<c-j>"

" lsp diagnostics {{{
"sign define LspDiagnosticsSignError text=✘ texthl=LspDiagnosticsSignError linehl= numhl=
"sign define LspDiagnosticsSignWarning text=⚠ texthl=LspDiagnosticsSignWarning linehl= numhl=
"function! SetLSPHighlights()
"  hi LspDiagnosticsSignError guifg=#ea4466 guibg=None guisp=None cterm=bold
"  hi LspDiagnosticsSignWarning guifg=#ea4466 guibg=None guisp=None cterm=bold
"  hi LspDiagnosticsDefaultError guifg=#ea4466 guibg=None guisp=None cterm=bold
"endfunction
"autocmd ColorScheme * call SetLSPHighlights()

nnoremap <silent> ]e <cmd>lua vim.diagnostic.goto_next()<CR>
nnoremap <silent> [e <cmd>lua vim.diagnostic.goto_prev()<CR>
" }}}

"Indient {{{
let g:indent_guides_enable_on_vim_startup = 1
set ts=4 sw=4 et
"let g:indent_guides_start_level = 2
"let g:indent_guides_guide_size = 1
" }}}

" color vim-one {{{
if (has('termguicolors'))
  set termguicolors
endif
" Fix italics in Vim
if !has('nvim')
  let &t_ZH="\e[3m"
  let &t_ZR="\e[23m"
endif

" NvimTree
nmap <F5> :NvimTreeToggle<CR>
"Open a folder and Nvim tree will show up
" autocmd StdinReadPre * let s:std_in=1
" autocmd VimEnter * if argc() == 1 && isdirectory(argv()[0]) && !exists("s:std_in") | exe 'NvimTreeToggle' argv()[0] | wincmd p | ene | exe 'cd '.argv()[0] | endif

" lightline
let g:material_terminal__italics = 1
let g:material_theme_style = 'default'
colorscheme material
let g:lightline = { 'colorscheme': 'material_vim' }
" }}}

"FZF floating window {{{
""fzf
"let $FZF_DEFAULT_OPTS=' --color=dark --color=fg:15,bg:-1,hl:1,fg+:#ffffff,bg+:0,hl+:1 --color=info:0,prompt:0,pointer:12,marker:4,spinner:11,header:-1 --layout=reverse  --margin=1,4'
let g:fzf_layout = { 'window': 'call FloatingFZF()' }

"for preview
let g:height = float2nr(&lines * 0.9)
let g:width = float2nr(&columns * 0.95)
let g:preview_width = float2nr(&columns * 0.4)
let g:fzf_buffers_jump = 1
let $FZF_DEFAULT_COMMAND =  "find * -path '*/\.*' -prune -o -path 'node_modules/**' -prune -o -path 'target/**' -prune -o -path 'dist/**' -prune -o  -type f -print -o -type l -print 2> /dev/null"
let $FZF_DEFAULT_OPTS=" --color=dark --color=fg:15,bg:-1,hl:1,fg+:#ffffff,bg+:0,hl+:1 --color=info:0,prompt:0,pointer:12,marker:4,spinner:11,header:-1 --layout=reverse  --margin=1,4 --preview 'if file -i {}|grep -q binary; then file -b {}; else bat --style=changes --color always --line-range :40 {}; fi' --preview-window right:" . g:preview_width
let g:fzf_layout = { 'window': 'call FloatingFZF(' . g:width . ',' . g:height . ')' }

function! FloatingFZF(width, height)
"function! FloatingFZF()
  let buf = nvim_create_buf(v:false, v:true)
  call setbufvar(buf, '&signcolumn', 'no')

  let height = a:height
  let width = a:width
  "let height = float2nr(10)
  "let width = float2nr(80)
  let horizontal = float2nr((&columns - width) / 2)
  let vertical = 1

  let opts = {
        \ 'relative': 'editor',
        \ 'row': vertical,
        \ 'col': horizontal,
        \ 'width': width,
        \ 'height': height,
        \ 'style': 'minimal'
        \ }

  call nvim_open_win(buf, v:true, opts)
endfunction

" fzf shortcut
nnoremap <silent> <C-p> :call fzf#vim#files('.', {'options': '--prompt ""'})<CR>
nnoremap <silent> <leader>b :Buffers<CR>
" FZF floating window end }}}

lua require("plugins")
