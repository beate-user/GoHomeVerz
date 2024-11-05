" if !&diff
"       execute pathogen#infect()
"       filetype plugin indent on
" endif
"set mouse=a             " Enable mouse usage (all modes)
set mouse=             " Enable mouse usage (all modes)
set showmatch           " Show matching brackets.
set hlsearch
set background=dark
set virtualedit=all
set nowrap
set number
"set cursorline
"set cursorcolumn
"colorscheme elflord
if &diff
        colorscheme industry
        syntax off
else
        colorscheme elflord
	syntax on
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
"augroup CursorLine
"au!
"       au VimEnter,WinEnter,BufWinEnter * setlocal cursorline cursorcolumn
"       au WinLeave * setlocal cursorline nocursorcolumn
"augroup END
highlight CursorColumn ctermbg=black
highlight CursorLine cterm=bold ctermbg=black
highlight StatusLineNC cterm=none 
"hi DiffAdd    ctermfg=white ctermbg=Green
"hi DiffChange ctermfg=white ctermbg=blue
"hi DiffDelete ctermfg=white ctermbg=Red
"hi DiffText   ctermfg=white ctermbg=magenta

" map a urxvt cube number to an xterm-256 cube number
fun! <SID>M(a)
    return strpart("0135", a:a, 1) + 0
endfun

" map a urxvt colour to an xterm-256 colour
fun! <SID>X(a)
    if &t_Co == 88
        return a:a
    else
        if a:a == 8
            return 237
        elseif a:a < 16
            return a:a
        elseif a:a > 79
            return 232 + (3 * (a:a - 80))
        else
            let l:b = a:a - 16
            let l:x = l:b % 4
            let l:y = (l:b / 4) % 4
            let l:z = (l:b / 16)
            return 16 + <SID>M(l:x) + (6 * <SID>M(l:y)) + (36 * <SID>M(l:z))
        endif
    endif
endfun

exec "hi DiffText       cterm=NONE   ctermfg=" . <SID>X(79) . " ctermbg=" . <SID>X(34)
exec "hi DiffChange     cterm=NONE   ctermfg=" . <SID>X(79) . " ctermbg=" . <SID>X(17)
exec "hi DiffDelete     cterm=NONE   ctermfg=" . <SID>X(79) . " ctermbg=" . <SID>X(32)
exec "hi DiffAdd        cterm=NONE   ctermfg=" . <SID>X(79) . " ctermbg=" . <SID>X(20)

