execute pathogen#infect()
filetype plugin indent on
syntax on
"set mouse=a             " Enable mouse usage (all modes)
set showmatch           " Show matching brackets.
set background=dark
set virtualedit=all
set nowrap
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
