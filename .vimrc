" show line
set number

" syntax
syntax on

" filetype
filetype on
filetype plugin indent on
filetype plugin on

" tab indent
set tabstop=2
set shiftwidth=2
set softtabstop=2
set autoindent
set expandtab
set smarttab

" ------------- plugin list start -------------
call plug#begin()
Plug 'ycm-core/YouCompleteMe'
Plug 'scrooloose/nerdtree'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'Raimondi/delimitMate'
Plug 'flazz/vim-colorschemes'
Plug 'mhinz/vim-startify'
Plug 'Yggdroot/indentLine'
Plug 'preservim/tagbar'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
call plug#end()
" ------------- plugin list end --------------

" color (depend on vim-colorschemes plugin)
set t_Co=256
" set background=dark
colorscheme molokai
"

" nerdtree settings
map <silent> <C-e> :NERDTreeToggle<CR>
"

" tagbar settings
map <silent> <leader>u :TagbarToggle<CR>
"

" fzf settings
nnoremap <C-p> :Files<CR>
nnoremap <C-g> :Ag<CR>
"

" YouCompleteMe
let g:ycm_add_preview_to_completeopt = 0
let g:ycm_show_diagnostics_ui = 0
let g:ycm_server_log_level = 'info'
let g:ycm_min_num_identifier_candidate_chars = 2
let g:ycm_collect_identifiers_from_comments_and_strings = 1
let g:ycm_complete_in_strings=1
let g:ycm_key_invoke_completion = '<c-z>'
set completeopt=menu,menuone

noremap <c-z> <NOP>

let g:ycm_semantic_triggers =  {
			\ 'c,cpp,python,java,go,erlang,perl': ['re!\w{2}'],
			\ 'cs,lua,javascript': ['re!\w{2}'],
			\ }

" airline settings
set laststatus=2
let g:airline_left_sep = ''
let g:airline_left_alt_sep = ''
let g:airline_right_sep = ''
let g:airline_right_alt_sep = ''
let g:airline_symbols = {}
let g:airline_symbols.branch = ''
let g:airline_symbols.readonly = ''
let g:airline_symbols.linenr = '☰'
let g:airline_symbols.maxlinenr = ''
let g:airline_symbols.dirty='⚡'
let g:airline_theme = 'onedark'
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#left_sep = ' '
let g:airline#extensions#tabline#left_alt_sep = '|'
"
