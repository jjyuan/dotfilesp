"
" brent yi
"


" #############################################
" > Initial setup <
" #############################################

" Disable vi compatability
set nocompatible

" Default to utf-8 (not needed/creates error for Neovim)
if !has('nvim')
    set encoding=utf-8
endif

" Remap <Leader> to <Space>
" This needs to be done before any leader-containing bindings happen
let mapleader = "\<Space>"

" Run shell commands using bash
set shell=/bin/bash

" Automatically install vim-plug plugin manager
let s:vim_plug_folder = (has('nvim') ? "$HOME/.config/nvim" : "$HOME/.vim") . '/autoload/'
let s:vim_plug_path = s:vim_plug_folder . 'plug.vim'
if empty(glob(s:vim_plug_path))
    if executable("curl")
        execute "silent !curl -fLo " . s:vim_plug_path . " --create-dirs "
            \ . "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
    elseif executable("wget")
        execute "silent !mkdir -p " . s:vim_plug_folder
        execute "silent !wget --output-document=" . s:vim_plug_path
            \ . " https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
    else
        echoerr "Need curl or wget to download vim-plug!"
    endif
    autocmd VimEnter * PlugUpdate --sync | source $MYVIMRC
endif


" #############################################
" > Plugins <
" #############################################

" Use Vundle-style path for vim-plug
let s:bundle_path = (has('nvim') ? '~/.config/nvim' : '~/.vim') . '/bundle'
execute "call plug#begin('" . s:bundle_path . "')"

" Navigation inside files
Plug 'easymotion/vim-easymotion'
Plug 'justinmk/vim-sneak'

" Shortcuts for manipulating quotes, brackets, parentheses, HTML tags
" + vim-repeat for making '.' work for vim-surround
Plug 'tpope/vim-surround'
Plug 'tpope/vim-repeat'

" Various path/repository-related helpers
" > Make gf, sfind, etc work better in repositories
" > Populates b:repo_file_search_root, b:repo_file_search_type,
"   b:repo_file_search_display variables
Plug 'brentyi/vim-repo-file-search'

" Doodads for Mercurial, Git
Plug 'tpope/vim-fugitive'
Plug 'ludovicchabant/vim-lawrencium'
if has('nvim') || has('patch-8.0.902')
    Plug 'mhinz/vim-signify'
else
    Plug 'mhinz/vim-signify', { 'branch': 'legacy' }
endif
" {{
    " Keybinding for opening diffs
    function! s:vc_diff()
        if b:repo_file_search_type == 'hg'
            Hgvdiff
        elseif b:repo_file_search_type == 'git'
            Gdiff
        endif
    endfunction
    nnoremap <silent> <Leader>vcd :call <SID>vc_diff()<CR>

    " Keybinding for printing repo status
    function! s:vc_status()
        if b:repo_file_search_type == 'hg'
            Hgstatus
        elseif b:repo_file_search_type == 'git'
            Gstatus
        endif
    endfunction
    nnoremap <silent> <Leader>vcs :call <SID>vc_status()<CR>

    " Keybinding for blame/annotate
    function! s:vc_blame()
        if b:repo_file_search_type == 'hg'
            Hgannotate
        elseif b:repo_file_search_type == 'git'
            Gblame
        endif
    endfunction
    nnoremap <silent> <Leader>vcb :call <SID>vc_blame()<CR>

    " For vim-signify
    set updatetime=300
" }}

" Fuzzy-find for files, buffers, tags!
let g:brent_use_fzf = get(g:, 'brent_use_fzf', 0)
if !g:brent_use_fzf
    " Default to ctrlp, which is really nice & portable!
    " Note: we've experimented with ctrlp-py-matcher, cpsm, etc, but support
    " across systems + vim versions has been shaky for all of them
    "
    Plug 'ctrlpvim/ctrlp.vim'
    " {{
        let g:ctrlp_extensions = ['tag', 'line']
        let g:ctrlp_show_hidden = 1
        let g:ctrlp_follow_symlinks=1
        let g:ctrlp_max_files=300000
        let g:ctrlp_switch_buffer = '0'
        let g:ctrlp_reuse_window = 1

        function! s:ctrlp_file_under_cursor()
            let g:ctrlp_default_input = expand('<cfile>')
            CtrlP
            let g:ctrlp_default_input = ''
        endfunction

        function! s:ctrlp_tag_under_cursor()
            let g:ctrlp_default_input = expand('<cword>')
            CtrlPTag
            let g:ctrlp_default_input = ''
        endfunction

        function! s:ctrlp_line_under_cursor()
            let g:ctrlp_default_input = expand('<cword>')
            CtrlPLine
            let g:ctrlp_default_input = ''
        endfunction

        nnoremap <silent> <Leader>p :CtrlPBuffer<CR>
        nnoremap <silent> <Leader>t :CtrlPTag<CR>
        nnoremap <silent> <Leader>gt :call <SID>ctrlp_tag_under_cursor()<CR>
        nnoremap <silent> <Leader>l :CtrlPLine<CR>
        nnoremap <silent> <Leader>gl :call <SID>ctrlp_line_under_cursor()<CR>
        nnoremap <silent> <Leader>gf :call <SID>ctrlp_file_under_cursor()<CR>
    " }}
else
    " FZF + ag is _much_ faster & actually useful when working with big repos
    "
    Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all', 'tag': '0.19.0' }
    Plug 'junegunn/fzf.vim'
    " {{
        function! s:smarter_fuzzy_file_search()
            execute "Files " . b:repo_file_search_root
        endfunction

        " Use ag if available
        if executable('ag')
            let $FZF_DEFAULT_COMMAND='ag --hidden --ignore .git -g ""'
        else
            echoerr "fzf enabled without ag!"
        endif

        " Bindings
        nnoremap <C-P> :call <SID>smarter_fuzzy_file_search()<CR>
        nnoremap <Leader>p :Buffers<CR>
        nnoremap <Leader>t :Tags<CR>
        nnoremap <Leader>gt :call fzf#vim#tags(expand('<cword>'))<CR>
        nnoremap <Leader>l :Lines<CR>
        nnoremap <Leader>gl :call fzf#vim#lines(expand('<cword>'))<CR>
        nnoremap <Leader>gf :call fzf#vim#files(b:repo_file_search_root, {
            \ 'options': '--query ' . expand('<cfile>')})<CR>

        " Band-aid for making fzf play nice w/ NERDTree + autochdir
        " Reproducing the error:
        "     (1) Open a file
        "     (2) Open another file w/ fzf
        "     (3) :edit .  # <= this should show some errors
        "     (4) Run `pwd` and `echo getcwd()` -- these will no longer match
        "
        " Oddly enough, this issue goes away when we either (a) use netrw
        " instead of nerdtree, (b) disable autochdir, or (c) add this autocmd
        " to fix the working directory state
        augroup AutochdirFix
            autocmd!
            autocmd BufReadPost * execute 'cd ' . getcwd()
        augroup END
    " }}
endif

" NERDTree for filesystem navigation/manipulation
Plug 'scrooloose/nerdtree'
" {{
    let g:NERDTreeShowHidden = 1
    let g:NERDTreeShowLineNumbers = 1
    autocmd FileType nerdtree setlocal relativenumber
    let g:NERDTreeMinimalUI = 1
    let g:NERDTreeFileExtensionHighlightFullName = 1
    let g:NERDTreeExactMatchHighlightFullName = 1
    let g:NERDTreePatternMatchHighlightFullName = 1
    let g:NERDTreeMapJumpNextSibling = '<Nop>'
    let g:NERDTreeMapJumpPrevSibling = '<Nop>'
    nnoremap <Leader>o :NERDTree<CR>

    augroup NERDTreeBindings
        " Match 'open in split' bindings of CtrlP and fzf
        autocmd!
        autocmd FileType nerdtree nmap <buffer> <C-v> s
        autocmd FileType nerdtree nmap <buffer> <C-x> i
    augroup END
" }}

" NERDTree extensions: syntax highlighting, version control indicators
Plug 'tiagofumo/vim-nerdtree-syntax-highlight'
Plug 'Xuyuanp/nerdtree-git-plugin'
Plug 'f4t-t0ny/nerdtree-hg-plugin'
" {{
    let g:NERDTreeIndicatorMapCustom = {
        \ 'Modified'  : "M",
        \ 'Staged'    : "+",
        \ 'Untracked' : "?",
        \ 'Renamed'   : "renamed",
        \ 'Unmerged'  : "unmerged",
        \ 'Deleted'   : "X",
        \ 'Dirty'     : "d",
        \ 'Clean'     : "c",
        \ 'Ignored'   : "-",
        \ 'Unknown'   : "??"
        \ }
" }}

" Massive language pack for syntax highlighting, etc
Plug 'sheerun/vim-polyglot'
" {{
    " Disable weird 'commas as pipes' feature in csv.vim
    let g:csv_no_conceal = 1

    " Markdown configuration
    let g:vim_markdown_conceal = 0
    let g:vim_markdown_auto_insert_bullets = 0
    let g:vim_markdown_new_list_item_indent = 0
    let g:vim_markdown_math = 1
" }}

" Fancy colors for CSS
Plug 'ap/vim-css-color'

" Rainbow highlighting + SQL-esque queries in CSV files
Plug 'mechatroner/rainbow_csv'

" Tag matching for HTML
Plug 'gregsexton/MatchTag'

" ~~ Color schemes ~~
Plug 'vim-scripts/xoria256.vim'
Plug 'tomasr/molokai'
Plug 'sjl/badwolf'

" Vim + tmux integration
Plug 'christoomey/vim-tmux-navigator'
Plug 'tmux-plugins/vim-tmux-focus-events'
" {{
    " https://github.com/tmux-plugins/vim-tmux-focus-events/issues/2
    augroup BlurArtifactBandaid
        autocmd!
        au FocusLost * silent redraw!
    augroup END
" }}

" Underline all instances of current word
Plug 'itchyny/vim-cursorword'

" Super intelligent indentation level detection
Plug 'tpope/vim-sleuth'
" {{
    " Default to 4 spaces
    set shiftwidth=4
    set expandtab

    " Load plugin early so user-defined autocmds override it
    runtime! plugin/sleuth.vim
" }}

" Shortcuts for adding comments (<Leader>cc, <Leader>ci, etc)
Plug 'scrooloose/nerdcommenter'
" {{
    let g:NERDSpaceDelims = 1
    let g:NERDCompactSexyComs = 1
    let g:NERDCommentEmptyLines = 1
    let g:NERDTrimTrailingWhitespace = 1
    let g:NERDDefaultAlign = 'left'
    let g:NERDAltDelims_python = 1
    let g:NERDAltDelims_cython = 1
    let g:NERDAltDelims_pyrex = 1
" }}

" Persistent cursor position + folds
Plug 'vim-scripts/restore_view.vim'
" {{
    set viewoptions=cursor,folds,slash,unix
" }}

" Helpers for Markdown:
" 1) Directly paste images
" 2) Live preview
"    > Our fork uses a pre-release version of KaTeX, to add support for
"    the globalGroup parameter
" 3) Table of contents generation
" 4) Emoji autocompletion
"    > Our fork removes emojis not found in common markdown parsers (Github,
"      markdown-it), and adds ones that are
Plug 'ferrine/md-img-paste.vim'
Plug 'brentyi/markdown-preview.nvim', { 'do': ':call mkdp#util#install()' }
Plug 'mzlogin/vim-markdown-toc'
Plug 'brentyi/vim-emoji'
" {{
    augroup MarkdownBindings
        autocmd!
        " Markdown paste image
        autocmd FileType markdown nnoremap <silent> <buffer>
            \ <Leader>mdpi :call mdip#MarkdownClipboardImage()<CR>
        " Markdown toggle preview
        autocmd FileType markdown nmap <silent> <buffer>
            \ <Leader>mdtp <Plug>MarkdownPreviewToggle
        autocmd FileType markdown setlocal completefunc=emoji#complete
        " Markdown generate TOC
        autocmd FileType markdown nnoremap <silent> <buffer>
            \ <Leader>mdtoc :GenTocGFM<CR>
    augroup END

    " Don't automatically close preview windows when we switch buffers
    let g:mkdp_auto_close = 0

    " KaTeX options
    let g:mkdp_preview_options = {
        \ 'katex': {
            \ 'globalGroup': 1,
            \  },
        \ }
" }}

" Display markers to signify different indentation levels
Plug 'Yggdroot/indentLine'
" {{
    let g:indentLine_char = '·'
    let g:indentLine_fileTypeExclude = ['json', 'markdown', 'tex']
" }}

" Status line
Plug 'itchyny/lightline.vim'
" {{
    " Display human-readable path to file
    " This is generated in vim-repo-file-search
    function! s:lightline_filepath()
        return get(b:, 'repo_file_search_display', "")
    endfunction

    let g:brent_lightline_colorscheme = get(g:, 'brent_lightline_colorscheme', "wombat")
    let g:lightline = {
        \ 'colorscheme': g:brent_lightline_colorscheme,
        \ 'active': {
        \   'left': [ [ 'mode', 'paste' ],
        \             [ 'readonly', 'filename', 'modified' ] ],
        \   'right': [ [ 'lineinfo' ],
        \              [ 'filetype', 'charvaluehex' ],
        \              [ 'gutentags' ],
        \              [ 'filepath' ],
        \              [ 'truncate' ]]
        \ },
        \ 'inactive': {
        \   'left': [ [ 'readonly', 'filename', 'modified' ] ],
        \   'right': [ [],
        \              [],
        \              [ 'filepath', 'lineinfo' ],
        \              [ 'truncate' ]]
        \ },
        \ 'component': {
        \   'charvaluehex': '0x%B',
        \   'gutentags': '%{GutentagsStatus()}%{gutentags#statusline("", "", "[ctags indexing]")}',
        \   'truncate': '%<',
        \ },
        \ 'component_function': {
        \   'filepath': string(function('s:lightline_filepath')),
        \ },
        \ }
" }}

" Show instance # in statusline when we search
Plug 'henrik/vim-indexed-search'

" Autocompletion for Github issues, users, etc
" > Our fork just adds more emojis :)
Plug 'brentyi/github-complete.vim'

" Lightweight autocompletion w/ tab key
Plug 'ajh17/VimCompletesMe'
" {{
    " Use j, k for selecting autocompletion results & enter for selection
    inoremap <expr> j ((pumvisible())?("\<C-n>"):("j"))
    inoremap <expr> k ((pumvisible())?("\<C-p>"):("k"))
    inoremap <expr> <CR> ((pumvisible())?("\<C-y>"):("\<CR>"))

    augroup Autocompletion
        autocmd!

        " Use omnicomplete by default for C++ (clang), Python (jedi), and
        " gitcommit (github-complete)
        autocmd FileType cpp,c,python,gitcommit let b:vcm_tab_complete = "omni"

        " Use vim-emoji for markdown
        autocmd FileType markdown let b:vcm_tab_complete = "user"
    augroup END

    " Binding to close preview windows (eg from autocompletion)
    nnoremap <silent> <Leader>pc :pc<CR>
" }}

" Python magic (auto-completion, definition jumping, etc)
Plug 'davidhalter/jedi-vim'
" {{
    " Disable automatic autocomplete popup
    let g:jedi#popup_on_dot=0

    " Leave docs open (close binding below)
    let g:jedi#auto_close_doc=0

    " Disable call signature popup
    let g:jedi#show_call_signatures=0
" }}

" C/C++ autocompletion
Plug 'xavierd/clang_complete'
" {{
    " Automatically find all installed versions of libclang, for when clang isn't
    " in the system search path
    function! s:find_libclang()
        " Delete the autocmd: we only need to find libclang once
        autocmd! FindLibclang

        " List all possible paths
        let l:clang_paths =
            \ glob('/usr/lib/llvm-*/lib/libclang.so.1', 0, 1)
            \ + glob('/usr/lib64/llvm-*/lib/libclang.so.1', 0, 1)
            \ + glob('/usr/lib/libclang.so.*', 0, 1)
            \ + glob('/usr/lib64/libclang.so.*', 0, 1)

        " Find the newest version and set g:clang_library_path
        let l:min_version = 0.0
        for l:path in l:clang_paths
            try
                " Figure out version from filename
                let l:current_version = str2float(
                    \ split(split(l:path, '-')[1], '/')[0])
            catch
                " No version in filename, let's just use pi...
                let l:current_version = 3.14159265
            endtry

            if filereadable(l:path) && l:current_version > l:min_version
                let g:clang_library_path=l:path
                echom "Found libclang: " . l:path . ", v" .
                       \ string(l:current_version)
                let l:min_version = l:current_version
            endif
        endfor

        " Failure message
        if !exists('g:clang_library_path')
            echom "Couldn't find libclang!"
        endif
    endfunction

    " Search for libclang when we open a C/C++ file
    augroup FindLibclang
        autocmd!
        autocmd Filetype c,cpp call s:find_libclang()
    augroup END
" }}

" Add pseudo-registers for copying to system clipboard (example usage: "+Y)
" > This basically emulates the +clipboard vim feature flag
" > Our fork contains important bug fixes, feature enhancements, etc from
"    unmerged pull requests made to the upstream repository
Plug 'brentyi/vim-fakeclip'

" Google's code format plugin + dependencies
" > Our vim-codefmt fork adds support for black, tweaks some autopep8/yapf
"   settings (these aren't used with black enabled, though)
Plug 'google/vim-maktaba'
Plug 'google/vim-glaive'
Plug 'brentyi/vim-codefmt'
" {{
    nnoremap <Leader>cf :FormatCode<CR>:redraw!<CR>
    vnoremap <Leader>cf :FormatLines<CR>:redraw!<CR>

    " Autoformatter configuration
    augroup CodeFmtSettings
        autocmd!
        autocmd FileType python nnoremap <buffer> <Leader>cf
            \ :call isort#Isort(1, line('$'), function('codefmt#FormatBuffer', ['black']))<CR>
            \ :redraw!<CR>
        autocmd FileType python vnoremap <buffer> <Leader>cf :FormatLines yapf<CR>:redraw!<CR>
        autocmd FileType javascript let b:codefmt_formatter='prettier'
    augroup END

    " Automatically find the newest installed version of clang-format
    function! s:find_clang_format()
        " Delete the autocmd: we only need to find clang-format once
        autocmd! FindClangFormat

        " If clang-format is in PATH, we don't need to do anything
        if executable('clang-format')
            echom "Found clang-format in $PATH"
                Glaive codefmt clang_format_executable='clang-format'
            return
        endif

        " List all possible paths
        let l:clang_paths =
            \ glob('/usr/lib/llvm-*/bin/clang-format', 0, 1)
            \ + glob('/usr/lib64/llvm-*/bin/clang-format', 0, 1)

        " Find the newest version and set clang_format_executable
        let l:min_version = 0.0
        for l:path in split(l:clang_paths, '\n')
            let l:current_version = str2float(
                \ split(split(l:path, '-')[1], '/')[0])

            if filereadable(l:path) && l:current_version > l:min_version
                Glaive codefmt clang_format_executable=`l:path`
                echom "Found clang-format: " . l:path
                let l:min_version = l:current_version
            endif
        endfor

        " Failure message
        if g:clang_format_executable == ""
            echom "Couldn't find clang-format!"
        endif
    endfunction

    " Search for clang-format when we open a C/C++ file
    augroup FindClangFormat
        autocmd!
        autocmd Filetype c,cpp call s:find_clang_format()
    augroup END
" }}

" Automated import sorting
Plug 'brentyi/isort.vim'
" {{
    " (Python) isort bindings
    augroup IsortMappings
        autocmd!
        autocmd FileType python nnoremap <buffer> <Leader>si :Isort<CR>
        autocmd FileType python vnoremap <buffer> <Leader>si :Isort<CR>
    augroup END
" }}

" Automated docstring template generation
Plug 'heavenshell/vim-pydocstring', { 'do': 'make install' }
" {{
    " (Python) Docstring bindings
    let g:pydocstring_formatter = get(g:, 'pydocstring_formatter', 'google')

    " <Plug>(pydocstring) needs to be mapped, or the plugin will override our
    " <C-l> binding
    nmap <Leader>pds <Plug>(pydocstring)
" }}

" Gutentags, for generating tag files
" > Our fork suppresses some errors for machines without ctags installed
Plug 'brentyi/vim-gutentags'
" {{
    " Set cache location
    let g:gutentags_cache_dir = '~/.cache/tags'

    " Lightline integration
    function! GutentagsStatus()
        if exists('g:gutentags_ctags_executable') && executable(expand(g:gutentags_ctags_executable, 1)) == 0
            return 'missing ctags'
        elseif !g:gutentags_enabled
            return 'ctags off'
        endif
        return ''
    endfunction
    augroup GutentagsStatusLineRefresher
        autocmd!
        autocmd User GutentagsUpdating call lightline#update()
        autocmd User GutentagsUpdated call lightline#update()
    augroup END
" }}

" Animations for fun?
Plug 'camspiers/animate.vim'
" {{
    let g:animate#duration = 150.0
    let g:animate#easing_func = 'animate#ease_out_quad'
    if !has('nvim')
        " This breaks in neovim for whatever reason
        let g:fzf_layout = {
            \ 'window': 'new | wincmd J | resize 1 | call animate#window_percent_height(0.5)'
            \ }
    endif
" }}

call plug#end()

" Initialize Glaive + codefmt
call glaive#Install()
Glaive codefmt plugin[mappings]

" Files for ctrlp + gutentags to ignore!
set wildignore=*.swp,*.o,*.pyc,*.pb
" Linux/MacOSX
set wildignore+=*/.git/*,*/.hg/*,*/.svn/*,*/.castle/*,*/.buckd/*,*/.venv/*,*/site-packages/*
" Windows ('noshellslash')
set wildignore+=*\\.git\\*,*\\.hg\\*,*\\.svn\\*,*\\.castle\\*,*\\.buckd\\*,*\\.venv\\*,*\\site-packages\\*


" #############################################
" > Visuals <
" #############################################

syntax on

" Line numbering
if v:version > 703
    " Vim versions after 703 support enabling both number and relativenumber
    " (To display relative numbers for all but the current line)
    set number
endif
set relativenumber

" Show at least 7 lines above/below the cursor when we scroll
set scrolloff=7

" Cursor crosshair when we enter insert mode
" Note we re-bind Ctrl+C in order for InsertLeave to be called
augroup InsertModeCrossHairs
    autocmd!
    autocmd InsertEnter * set cursorline
    autocmd InsertLeave * set nocursorline
    autocmd InsertEnter * set cursorcolumn
    autocmd InsertLeave * set nocursorcolumn
augroup END
inoremap <C-C> <Esc>

" Configuring colors
set background=dark
let g:brent_colorscheme = get(g:, 'brent_colorscheme', "xoria256")
if g:brent_colorscheme == 'legacy'
    " Fallback colors for some legacy terminals
    set t_Co=16
    set foldcolumn=1
    hi FoldColumn ctermbg=7
    hi LineNr cterm=bold ctermfg=0 ctermbg=0
    hi CursorLineNr ctermfg=0 ctermbg=7
    hi Visual cterm=bold ctermbg=1
    hi TrailingWhitespace ctermbg=1
    hi Search ctermfg=4 ctermbg=7
else
    " When we have 256 colors available
    " (This is usually true)
    set t_Co=256
    execute "colorscheme " . g:brent_colorscheme
    hi LineNr ctermfg=241 ctermbg=234
    hi CursorLineNr cterm=bold ctermfg=232 ctermbg=250
    hi Visual cterm=bold ctermbg=238
    hi TrailingWhitespace ctermbg=52
    let g:indentLine_color_term=237
endif
hi MatchParen cterm=bold,underline ctermbg=none ctermfg=7
hi VertSplit ctermfg=0 ctermbg=0

augroup MatchTrailingWhitespace
    autocmd!
    autocmd VimEnter,BufEnter,WinEnter * call matchadd('TrailingWhitespace', '\s\+$')
augroup END

" Visually different markers for various types of whitespace
" (for distinguishing tabs vs spaces)
set list listchars=tab:❘-,trail:\ ,extends:»,precedes:«,nbsp:×

" Show the statusline, always!
set laststatus=2

" Hide redundant mode indicator underneath statusline
set noshowmode

" Highlight searches
set hlsearch

"""" general usability
let mapleader = "\<Space>"
vmap [[ <Esc>
vmap jk <Esc>
imap [[ <Esc>
imap jk <Esc>

" #############################################
" > General behavior stuff <
" #############################################

" Set plugin, indentation settings automatically based on the filetype
filetype plugin indent on

" Make escape insert mode zippier
set timeoutlen=300 ttimeoutlen=10

" Allow backspacing over everything (eg line breaks)
set backspace=2

" Expand history of saved commands
set history=35

" Enable modeline for file-specific vim settings
" This is insecure on some vim versions and should maybe be removed?
set modeline

" Automatically change working directory to current file location
set autochdir

" Fold behavior tweaks
set foldmethod=indent
set foldlevel=99

" Passive FTP mode for remote netrw
let g:netrw_ftp_cmd = 'ftp -p'


" #############################################
" > Key mappings for usability <
" #############################################

" Alternate escape key bindings
vmap [[ <Esc>
vmap ;; <Esc>
imap [[ <Esc>
imap ;; <Esc>

" Search utilities -- highlight matches, clear highlighting with <Esc>
nnoremap <silent> <Esc> :noh<CR>:redraw!<CR><Esc>
nnoremap <Esc>^[ <Esc>^[

" Use backslash to toggle folds
nnoremap <Bslash> za

" Binding to toggle line numbering -- useful for copy & paste, etc
if v:version > 703
    nnoremap <Leader>tln :set number!<CR>:set relativenumber!<CR>
else
    nnoremap <Leader>tln :set relativenumber!<CR>
endif

" Bindings for lower-effort writing, quitting, reloading
nnoremap <Leader>wq :wq<CR>
nnoremap <Leader>w :w<CR>
nnoremap <Leader>q :q<CR>
nnoremap <Leader>q! :q!<CR>
nnoremap <Leader>e :e<CR>
nnoremap <Leader>e! :e!<CR>

" Binding to switch into/out of PASTE mode
nnoremap <Leader>ip :set invpaste<CR>

" Binding to trim trailing whitespaces in current file
nnoremap <Leader>ttws :%s/\s\+$//e<CR>

" Binding to 'replace this word'
nnoremap <Leader>rtw :%s/\<<C-r><C-w>\>/

" Switch ' and ` for jumps: ' is much more intuitive and easier to access
onoremap ' `
vnoremap ' `
nnoremap ' `
onoremap ` '
vnoremap ` '
nnoremap ` '

" Bindings for buffer stuff
" > bd: delete current buffer
" > bc: clear all but current buffer
" > baa: open buffer for all files w/ same extension in current directory
nnoremap <silent> <Leader>bd :bd<CR>
nnoremap <silent> <Leader>bc :%bd\|e#<CR>
function! s:buffer_add_all()
    " Get a full path to the current file
    let l:path = expand("%:p")

    " Chop off the filename and add wildcard
    let l:pattern = l:path[:-len(expand("%:t")) - 1] . "**/*." . expand("%:e")
    echom "Loaded buffers matching pattern: " . l:pattern
    for l:path in split(glob(l:pattern), '\n')
        let filesize = getfsize(l:path)
        if filesize > 0 && filesize < 80000
            execute "badd " . l:path
        endif
    endfor
endfunction
nnoremap <silent> <Leader>baa :call <SID>buffer_add_all()<CR>


" Bindings for switching between tabs
nnoremap <silent> <Leader>tt :tabnew<CR>
nnoremap <silent> <Leader>n :tabn<CR>

" 'Force write' binding for writing with sudo
" Helpful if we don't have permissions for a specific file
cmap W! w !sudo tee >/dev/null %


" #############################################
" > Configuring splits <
" #############################################

" Match tmux behavior + bindings (with <C-w> instead of <C-b>)
set splitbelow
set splitright
nmap <C-w>" :sp<CR>
nmap <C-w>% :vsp<CR>


" #############################################
" > Friendly mode <
" ##############################################

" This maps <Leader>f to toggle between:
"  - 'Default mode': arrow keys resize splits, mouse disabled
"  - 'Friendly mode': arrow keys, mouse behave as usual

let s:friendly_mode = 1
function! s:toggle_friendly_mode(verbose)
    if s:friendly_mode
        nnoremap <silent> <Up>
                    \ :<C-U>call animate#window_delta_height(v:count1 * 8)<CR>
        nnoremap <silent> <Down>
                    \ :<C-U>call animate#window_delta_height(v:count1 * -8)<CR>
        nnoremap <silent> <Left>
                    \ :<C-U>call animate#window_delta_width(v:count1 * -8)<CR>
        nnoremap <silent> <Right>
                    \ :<C-U>call animate#window_delta_width(v:count1 * 8)<CR>
        set mouse=
        let s:friendly_mode = 0

        if a:verbose
            echo "disabled friendly mode!"
        endif
    else
        unmap <silent> <Up>
        unmap <silent> <Down>
        unmap <silent> <Right>
        unmap <silent> <Left>
        set mouse=a
        let s:friendly_mode = 1

        if a:verbose
            echo "enabled friendly mode!"
        endif
    endif
endfunction
call <SID>toggle_friendly_mode(0)
nnoremap <silent> <Leader>f :call <SID>toggle_friendly_mode(1)<CR>


" #############################################
" > Filetype-specific configurations <
" #############################################

augroup FiletypeHelpers
    autocmd!

    " (ROS) Launch files should be highlighted as xml
    autocmd BufNewFile,BufRead *.launch set filetype=xml

    " (Makefile) Only tabs are supported
    autocmd FileType make setlocal noexpandtab | setlocal shiftwidth&

    " (Buck) Highlight as python
    autocmd BufNewFile,BufRead BUCK* set filetype=python
    autocmd BufNewFile,BufRead TARGETS set filetype=python

    " (C++) Angle bracket matching for templates
    autocmd FileType cpp setlocal matchpairs+=<:>

    " (Python/C++/Markdown) Highlight lines that are too long
    " 88 for Python (to match black defaults)
    " 80 for Markdown (to match prettier defaults)
    " 100 for C++ (clang-format is 80 by default, but we've been overriding to 100)
    highlight OverLength ctermbg=darkgrey
    autocmd VimEnter,BufEnter,WinEnter *.py call matchadd('OverLength', '\%>88v.\+')
    autocmd VimEnter,BufEnter,WinEnter *.md call matchadd('OverLength', '\%>80v.\+')
    autocmd VimEnter,BufEnter,WinEnter *.cpp call matchadd('OverLength', '\%>100v.\+')
    autocmd VimLeave,BufLeave,WinLeave * call
        \ clearmatches()

    " (C/C++) Automatically insert header gates for h/hpp files
    function! s:insert_gates()
        let gatename = substitute(toupper(expand("%:t")), "\\.", "_", "g")
        execute "normal! i#ifndef " . gatename
        execute "normal! o#define " . gatename . " "
        execute "normal! Go#endif /* " . gatename . " */"
        normal! kk
    endfunction
    autocmd BufNewFile *.{h,hpp} call <SID>insert_gates()

    " (Commits) Enable spellcheck
    autocmd FileType gitcommit,hgcommit setlocal spell
augroup END


" #############################################
" > Automatic window renaming for tmux <
" #############################################

if exists('$TMUX')
    augroup TmuxHelpers
      " TODO: fix strange behavior when we break-pane in tmux
        autocmd!
        autocmd BufReadPost,FileReadPost,BufNewFile,BufEnter,FocusGained * call system("tmux rename-window 'vim " . expand("%:t") . "'")
        autocmd VimLeave,FocusLost * call system("tmux set-window-option automatic-rename")
    augroup END
endif


" #############################################
" > Spellcheck <
" #############################################

map <F5> :setlocal spell! spelllang=en_us<CR>
inoremap <F5> <C-\><C-O>:setlocal spelllang=en_us spell! spell?<CR>
hi clear SpellBad
hi SpellBad cterm=bold,italic ctermfg=red


" #############################################
" > Meta <
" #############################################

augroup AutoReloadVimRC
    autocmd!
    autocmd BufWritePost $MYVIMRC source $MYVIMRC

    " For init.vim->.vimrc symlinks in Neovim
    autocmd BufWritePost .vimrc source $MYVIMRC
augroup END

