set pastetoggle=<F10>
set nocompatible              " be iMproved, required
filetype off                  " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
" alternatively, pass a path where Vundle should install plugins
"call vundle#begin('~/some/path/here')

" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'

" The following are examples of different formats supported.
" Keep Plugin commands between vundle#begin/end.
" plugin on GitHub repo
Plugin 'tpope/vim-fugitive'
" plugin from http://vim-scripts.org/vim/scripts.html
" Plugin 'L9'
" Git plugin not hosted on GitHub
""Plugin 'git://git.wincent.com/command-t.git'
" git repos on your local machine (i.e. when working on your own plugin)
""Plugin 'file:///home/gmarik/path/to/plugin'
" The sparkup vim script is in a subdirectory of this repo called vim.
" Pass the path to set the runtimepath properly.
Plugin 'rstacruz/sparkup', {'rtp': 'vim/'}
" Install L9 and avoid a Naming conflict if you've already installed a
" different version somewhere else.
" Plugin 'ascenator/L9', {'name': 'newL9'}
Plugin 'Valloric/YouCompleteMe'
Plugin 'Lokaltog/vim-powerline'
Plugin 'scrooloose/nerdtree'
Plugin 'Yggdroot/indentLine'
Plugin 'jiangmiao/auto-pairs'
Plugin 'tell-k/vim-autopep8'
Plugin 'scrooloose/nerdcommenter'
" vim-visual-multi
Plugin 'mg979/vim-visual-multi', {'branch': 'master'}

" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required
" To ignore plugin indent changes, instead use:
"filetype plugin on
"
" Brief help
" :PluginList       - lists configured plugins
" :PluginInstall    - installs plugins; append `!` to update or just :PluginUpdate
" :PluginSearch foo - searches for foo; append `!` to refresh local cache
" :PluginClean      - confirms removal of unused plugins; append `!` to auto-approve removal
"
" see :h vundle for more details or wiki for FAQ
" Put your non-Plugin stuff after this line
"

" You complete Me
" YouCompleteMe {{{
" map to <LocalLeader>K to act like default man.vim's keymapping.
"nnoremap <silent><LocalLeader>K :YcmCompleter GoToDefinition<CR>
let g:ycm_global_ycm_extra_conf='~/.vim/bundle/YouCompleteMe/third_party/ycmd/cpp/ycm/.ycm_extra_conf.py'
let g:ycm_key_invoke_completion=''
let g:ycm_min_num_of_chars_for_completion=1
let g:ycm_confirm_extra_conf=0   "每次直接加载该文件，不提示是否要加载
let g:ycm_autoclose_preview_window_after_completion = 1
let g:ycm_autoclose_preview_window_after_insertion = 1
"let g:ycm_show_diagnostics_ui = 0
let g:ycm_python_binary_path = 'python'
let g:ycm_path_to_python_interpreter='python'
"let g:ycm_key_list_select_completion = ['<tab>', '<c-n>', '<Down>']
"let g:ycm_key_list_previous_completion = ['<s-tab>', '<c-p>', '<Up>']
"let g:ycm_filetype_specific_completion_to_disable = {
"     \ 'vim': 1,
"         \ 'gitcommit': 1
"             \}
" }}}

"Jedi-vim
let g:jedi#auto_vim_configuration = 0
let g:jedi#use_tabs_not_buffers = 1


" tap F5 to run python 
"map <F5> :Autopep8<CR> :w<CR> :call RunPython()<CR>
map <F5> :w<CR> :call RunPython()<CR>

function RunPython()
	let mp = &makeprg
	let ef = &errorformat
	let exeFile = expand("%:t")
	setlocal makeprg=python\ -u
	set efm=%C\ %.%#,%A\ \ File\ \"%f\"\\,\ line\ %l%.%#,%Z%[%^\ ]%\\@=%m 
	silent make %
	copen
	let &makeprg = mp
	let &errorformat = ef
endfunction
