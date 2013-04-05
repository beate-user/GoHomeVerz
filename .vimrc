execute pathogen#infect()
filetype plugin indent on
syntax on
"set mouse=a             " Enable mouse usage (all modes)
set showmatch           " Show matching brackets.
set hlsearch
set background=dark
set virtualedit=all
set nowrap
set number
"set cursorline
"set cursorcolumn
"colorscheme delek
colorscheme default
if &diff
"	colorscheme peaksea
        syntax off
endif 
set diffopt=filler,iwhite
        set diffexpr=MyDiff()
        function MyDiff()
           let opt = ""
           if &diffopt =~ "icase"
             let opt = opt . "-i "
           endif
           if &diffopt =~ "iwhite"
             let opt = opt . "-b -w "
           endif
           silent execute "!diff -a --binary " . opt . v:fname_in . " " . v:fname_new .
                \  " > " . v:fname_out
        endfunction

let g:miniBufExplMapWindowNavVim = 1
let g:miniBufExplMapWindowNavArrows = 1
let g:miniBufExplMapCTabSwitchBufs = 1
let g:miniBufExplModSelTarget = 1  
set nocompatible   " Disable vi-compatibility
set laststatus=2   " Always show the statusline
set encoding=utf-8 " Necessary to show unicode glyphs
set t_Co=256 " Explicitly tell vim that the terminal supports 256 colors
"let g:Powerline_symbols = 'unicode'
"filetype plugin on
augroup CursorLine
au!
	au VimEnter,WinEnter,BufWinEnter * setlocal cursorline cursorcolumn
	au WinLeave * setlocal cursorline nocursorcolumn  
augroup END
highlight CursorColumn ctermbg=black
highlight CursorLine cterm=bold ctermbg=black
highlight StatusLineNC cterm=none 
