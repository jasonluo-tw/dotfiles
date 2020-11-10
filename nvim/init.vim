set pastetoggle=<F10>
"set nocompatible              " be iMproved, required
"filetype off                  " required
filetype plugin on

call plug#begin('~/.config/nvim/plugins')
" lsp
Plug 'neovim/nvim-lspconfig'
Plug 'nvim-lua/completion-nvim'
Plug 'nvim-lua/diagnostic-nvim'
Plug 'liuchengxu/vista.vim', { 'on': ['Vista', 'Vista!', 'Vista!!'] }

" folders
"
Plug 'preservim/nerdtree'
Plug 'Xuyuanp/nerdtree-git-plugin'
" zoom in/out
Plug 'troydm/zoomwintab.vim', { 'on': 'ZoomWinTabToggle' }
" <C-d>
Plug 'mg979/vim-visual-multi'
" linter
Plug 'dense-analysis/ale', { 'for': ['javascript', 'typescript'] }
" snippets <C-j> to expand snippets

Plug 'SirVer/ultisnips'
Plug 'honza/vim-snippets'
" filetype
Plug 'sheerun/vim-polyglot'

" search
let b:fzf_on = ['Files', 'GitFiles', 'Buffers', 'Commands', 'Rg', 'BCommits', 'Maps']
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim', { 'on': b:fzf_on }
Plug 'mhinz/vim-grepper', { 'on': ['Grepper', '<plug>(GrepperOperator)'] }
"Indent
Plug 'nathanaelkane/vim-indent-guides'
"auto pairs 
Plug 'jiangmiao/auto-pairs'
" fast commenter
" usage \ + cc to commend, \ + cu to uncommend
Plug 'scrooloose/nerdcommenter'
"Plug 'tell-k/vim-autopep8'

"interface
Plug 'itchyny/lightline.vim'
Plug 'edkolev/tmuxline.vim', { 'on': ['Tmuxline', 'TmuxlineSnapshot'] }
"Plug 'rakr/vim-one'
Plug 'kaicataldo/material.vim', { 'branch': 'main' }

"emmet
" usage <C-y>, to expand the html tag
Plug 'mattn/emmet-vim'

" floating terminal
Plug 'voldikss/vim-floaterm'

call plug#end()


"lua require'nvim_lsp'.pyls.setup{on_attach=require'completion'.on_attach}
lua require("lsp_config")

" Use completion-nvim in every buffer
"autocmd BufEnter * lua require'completion'.on_attach()

" use omni completion provided by lsp
autocmd Filetype python,javascript,typescript setlocal omnifunc=v:lua.vim.lsp.omnifunc


" snipet
let g:UltiSnipsExpandTrigger="<c-j>"

""" nvim complettion
""" Use <Tab> and <S-Tab> to navigate through popup menu
inoremap <expr> <Tab>   pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
""" Set completeopt to have a better completion experience
set completeopt=menuone,noinsert,noselect

" Avoid showing message extra message when using completion
set shortmess+=c

"nnoremap <silent>gd    <cmd>lua vim.lsp.buf.declaration()<CR>
"nnoremap <silent><c-]> <cmd>lua vim.lsp.buf.definition()<CR>
"nnoremap <silent>K     <cmd>lua vim.lsp.buf.hover()<CR>
let g:diagnostic_enable_virtual_text = 1
let g:diagnostic_virtual_text_prefix = '?'
let g:diagnostic_insert_delay = 1
call sign_define("LspDiagnosticsWarningSign", {"text" : "W", "texthl" : "LspDiagnosticsWarning"})
call sign_define("LspDiagnosticsErrorSign", {"text" : "x", "texthl" : "LspDiagnosticsError"})
nnoremap <silent> ]e <cmd>NextDiagnosticCycle<CR>
nnoremap <silent> [e <cmd>PrevDiagnosticCycle<CR>

"nerd tree
nmap <F5> :NERDTreeToggle<CR>
"Open a folder and nerd tree will show up
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 1 && isdirectory(argv()[0]) && !exists("s:std_in") | exe 'NERDTree' argv()[0] | wincmd p | ene | exe 'cd '.argv()[0] | endif
"If only nerd tree window left, nvim will close
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif

"Indient
let g:indent_guides_enable_on_vim_startup = 1
set ts=4 sw=4 et
"let g:indent_guides_start_level = 2
"let g:indent_guides_guide_size = 1

" Vista.vim {{{
let g:vista_default_executive = 'nvim_lsp'
let g:vista#renderer#enable_icon = 0
let g:vista_no_mappings = 1
nnoremap <localLeader>t <cmd>Vista!!<CR>
" }}}

" color vim-one
if (has('termguicolors'))
  set termguicolors
endif
" Fix italics in Vim
if !has('nvim')
  let &t_ZH="\e[3m"
  let &t_ZR="\e[23m"
endif

let g:material_terminal__italics = 1
let g:material_theme_style = 'default'
colorscheme material
let g:lightline = { 'colorscheme': 'material_vim' }

"vista
nmap <F6> :Vista!!<CR>
