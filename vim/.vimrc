" Tibor's vim configuration.

" Define leaders
let mapleader = ' '
let maplocalleader = ' '

" Specify directory for plugins
call plug#begin('~/.vim/plugged')

" Gruvbox colour scheme
Plug 'morhetz/gruvbox'
    " Note: if gruvbox colours don't look quite right, don't forget to
    " source $HOME/.vim/plugged/gruvbox/gruvbox_256palette.sh
    " in your shell starting scripts.
    let g:gruvbox_contrast_dark='medium'
    let g:gruvbox_contrast_light='hard'
    set background=dark

" Editing
Plug 'tpope/vim-surround'
Plug 'tpope/vim-commentary'
Plug 'ntpeters/vim-better-whitespace'
    let g:strip_whitespace_confirm=0
    let g:strip_whitespace_on_save=1

" Undo tree
Plug 'mbbill/undotree', { 'on': 'UndotreeToggle' }
    let g:undotree_WindowLayout = 2
    nmap <Leader>u :UndotreeToggle<CR>

" Jumping around
Plug 'justinmk/vim-sneak'
    let g:sneak#label = 1
    let g:sneak#s_next = 1
    map f <Plug>Sneak_f
    map F <Plug>Sneak_F
    map t <Plug>Sneak_t
    map T <Plug>Sneak_T

" Fuzzy finder
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'
    " Set fzf colours to match the gruvbox colorscheme
    let g:fzf_colors = {
      \ 'fg':      ['fg', 'GruvboxFg3'],
      \ 'bg':      ['fg', 'GruvboxBg0'],
      \ 'hl':      ['fg', 'GruvboxBlue'],
      \ 'fg+':     ['fg', 'GruvboxFg1'],
      \ 'bg+':     ['fg', 'GruvboxBg1'],
      \ 'hl+':     ['fg', 'GruvboxBlue'],
      \ 'info':    ['fg', 'GruvboxAqua'],
      \ 'prompt':  ['fg', 'GruvboxFg4'],
      \ 'pointer': ['fg', 'GruvboxAqua'],
      \ 'marker':  ['fg', 'GruvboxAqua'],
      \ 'spinner': ['fg', 'GruvboxAqua'],
      \ 'header':  ['fg', 'GruvboxBg3'],
      \ 'gutter':  ['fg', 'GruvboxBg0']
      \ }
    " Fuzzy finder basic mappings
    nnoremap <silent> <Leader>f :FZF -m<CR>
    nnoremap <silent> <Leader>b :Buffers<CR>
    nnoremap <silent> <Leader>s :Lines<CR>
    nnoremap <silent> <Leader>r :Rg<CR>
    " Fuzzy finder selecting mappings
    nmap <leader><tab> <plug>(fzf-maps-n)
    xmap <leader><tab> <plug>(fzf-maps-x)
    omap <leader><tab> <plug>(fzf-maps-o)
    " Fuzzy finder insert mode completion
    imap <c-x><c-k> <plug>(fzf-complete-word)
    imap <c-x><c-f> <plug>(fzf-complete-path)
    imap <c-x><c-j> <plug>(fzf-complete-file-ag)
    imap <c-x><c-l> <plug>(fzf-complete-line)
    " Fuzzy open files in horizontal split
    nnoremap <silent> <Leader>eh :call fzf#run({
    \   'down': '40%',
    \   'sink': 'botright split' })<CR>
    " Fuzzy open files in vertical horizontal split
    nnoremap <silent> <Leader>ev :call fzf#run({
    \   'right': winwidth('.') / 2,
    \   'sink':  'vertical botright split' })<CR>

" Git
Plug 'tpope/vim-fugitive'
    nnoremap <Leader>ga :Git add %:p<CR><CR>
    nnoremap <Leader>gb :Gbrowse<CR>
    nnoremap <Leader>gB :Gblame<CR>
    nnoremap <Leader>gd :Gdiff<CR>
    nnoremap <Leader>gk :exe ':!cd ' . expand('%:p:h') . '; git k'<CR>
    nnoremap <Leader>gka :exe ':!cd ' . expand('%:p:h') . '; git ka'<CR>
    nnoremap <Leader>gl :silent! Glog<CR>:bot copen<CR>
    nnoremap <Leader>gs :Gstatus<CR>
Plug 'mhinz/vim-signify'
    let g:signify_sign_show_count = 0
    let g:signify_sign_show_text = 1
    let g:signify_sign_change = '~'
    nmap <Leader>h <Plug>(signify-next-hunk)
    nmap <Leader>H <Plug>(signify-prev-hunk)
Plug 'junegunn/gv.vim'
    nnoremap <Leader>gv :GV<CR>
    nnoremap <Leader>gV :GV!<CR>

" GitHub
Plug 'tpope/vim-rhubarb'

" GnuPG
Plug 'jamessan/vim-gnupg'

" Python
Plug 'psf/black', { 'for': 'python' }

" Markdown
Plug 'plasticboy/vim-markdown', { 'for': 'markdown' }
    let g:vim_markdown_folding_disabled=1

" TeX
Plug 'lervag/vimtex', { 'for': 'tex' }
    let g:vimtex_view_method = 'zathura'

" Tmux
Plug 'christoomey/vim-tmux-navigator'
    " Tmux navigation via C-hjkl
    nnoremap <silent> <c-h> :TmuxNavigateLeft<cr>
    nnoremap <silent> <c-j> :TmuxNavigateDown<cr>
    nnoremap <silent> <c-k> :TmuxNavigateUp<cr>
    nnoremap <silent> <c-l> :TmuxNavigateRight<cr>
    nnoremap <silent> <c-\> :TmuxNavigatePrevious<cr>
    " Allow pane switching directly from insert mode
    inoremap <silent> <c-h> <esc>:TmuxNavigateLeft<cr>
    inoremap <silent> <c-j> <esc>:TmuxNavigateDown<cr>
    inoremap <silent> <c-k> <esc>:TmuxNavigateUp<cr>
    inoremap <silent> <c-l> <esc>:TmuxNavigateRight<cr>
    inoremap <silent> <c-\> <esc>:TmuxNavigatePrevious<cr>

" Vimux
Plug 'benmills/vimux'
    " Prompt for a command to run in another tmux runner pane
    map <Leader>vp :VimuxPromptCommand<CR>
    " Repeat last run command
    map <Leader>vl :VimuxRunLastCommand<CR>
    " Inspect tmux runner pane
    map <Leader>vi :VimuxInspectRunner<CR>
    " Zoom tmux runner pane
    map <Leader>vz :VimuxZoomRunner<CR>

" Ale
Plug 'w0rp/ale'
    " Use only flake8 linter for Python for now
    let g:ale_linters = {
        \ 'python': ['flake8'],
        \ }
    let g:ale_fixers = {
        \ 'javascript': ['prettier'],
        \ 'python': ['black'],
        \ '*': ['remove_trailing_lines', 'trim_whitespace'],
        \ }
    let g:ale_lint_delay = 1000
    let g:ale_open_list = 1
    let g:ale_lint_on_save = 1
    let g:ale_lint_on_text_changed = 0
    nmap <Leader>ta :ALEToggle<CR>
    nmap <Leader>an <Plug>(ale_next_wrap)
    nmap <Leader>ap <Plug>(ale_previous_wrap)

" Snippets
Plug 'SirVer/ultisnips'
Plug 'honza/vim-snippets'

" Quickfix, location, spell check and other jumps
Plug 'tpope/vim-unimpaired'

" Distraction-free writing
Plug 'junegunn/limelight.vim'
    nmap <silent> <Leader>tl :Limelight!!<CR>
    let g:limelight_conceal_ctermfg = 243
    let g:limelight_conceal_guifg = '#7c6f64'
Plug 'junegunn/goyo.vim'
    nmap <silent> <Leader>tg :Goyo<CR>
    function! s:goyo_leave()
        " Tune down status line to our defaults (see below)
        highlight StatusLine ctermbg=237 ctermfg=248 cterm=NONE
        highlight StatusLineNC ctermbg=237 ctermfg=245 cterm=NONE
    endfunction
    autocmd! User GoyoLeave nested call <SID>goyo_leave()

" Email address completion for Mutt/Notmuch
Plug 'adborden/vim-notmuch-address'

" Initialize plugin system
call plug#end()

" Show line numbers
set number relativenumber

" Do not highlight cursor line
set nocursorline

" Break lines at word (requires Wrap lines)
set linebreak

" Wrap-broken line prefix
let &showbreak = '↳ '

" Wrap long lines by default
set wrap

" Line wrap (don't limit text width)
set textwidth=0

" Highlight matching brace
set showmatch

" Enable spell-checking
set spell
set spell spelllang=en_gb
nmap <Leader>ts :setlocal spell! spelllang=en_gb<CR>

" Toggle paste
nmap <Leader>tp :setlocal paste!<CR>

" Use visual bell (no beeping)
set visualbell

" Highlight all search results
set hlsearch

" Enable smart-case search
set smartcase

" Always case-insensitive
set ignorecase

" Searches for strings incrementally
set incsearch

" Auto-indent new lines
set autoindent

" Use spaces instead of tabs
set expandtab

" Number of auto-indent spaces
set shiftwidth=4

" Enable smart-indent
set smartindent

" Enable smart-tabs
set smarttab

" Number of spaces per Tab
set softtabstop=4

" Show row and column ruler information
set ruler

" Number of undo levels
set undolevels=1000

" Backspace behaviour
set backspace=indent,eol,start

" Always show status line
set laststatus=2

" Simple non-obtrusive status line
function! s:statusline_expr()
    let mod = "%{&modified ? '[+] ' : !&modifiable ? '[x] ' : ''}"
    let ro  = "%{&readonly ? '[RO] ' : ''}"
    let ft  = "%{len(&filetype) ? '['.&filetype.'] ' : ''}"
    let fug = "%{exists('g:loaded_fugitive') ? fugitive#statusline() : ''}"
    let sep = ' %= '
    let pos = ' %-12(%l : %c%V%) '
    let pct = ' %P'
  return '[%n] %F %<'.mod.ro.ft.fug.sep.pos.pct
endfunction
let &statusline = s:statusline_expr()

" Do not join spaces when reformatting paragraphs
set nojoinspaces

" Disable folding
set foldlevelstart=99

" Persistent undo
set undodir=~/.vim/undo
set undofile

" Allow mouse
set mouse=a

" Use system clipboard
set clipboard=unnamed

" Shorter mapped key sequence wait time limit
set timeoutlen=500

" Faster update time for asynchronous operations
set updatetime=100

" Always show sign column to keep the same visual width
set signcolumn=yes

" Location
nnoremap <Leader>l :lnext<cr>zz
nnoremap <Leader>L :lprev<cr>zz

" Quickfix
nnoremap <Leader>q :cnext<cr>zz
nnoremap <Leader>Q :cprev<cr>zz

" Jump to last editing position
autocmd BufReadPost *
    \ if line("'\"") >= 1 && line("'\"") <= line("$") && &ft !~# 'commit'
    \ |   exe "normal! g`\""
    \ | endif

" Use format flowed and Goyo mode in Mutt
autocmd BufRead,BufNewFile /tmp/mutt-* set tw=72 wm=0 fo+=w
autocmd BufRead,BufNewFile /tmp/mutt-* DisableStripWhitespaceOnSave
autocmd BufRead,BufNewFile /tmp/mutt-* :Goyo

" Set colour scheme and tune it down a bit
colorscheme gruvbox
highlight clear SignColumn
highlight StatusLine ctermbg=237 ctermfg=248 cterm=NONE
highlight StatusLineNC ctermbg=237 ctermfg=245 cterm=NONE
