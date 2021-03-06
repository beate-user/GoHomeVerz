" Description:  Omni completion script for resolve namespace
" Maintainer:   fanhe <fanhed@163.com>
" Create:       2011 May 14
" License:      GPLv2

if exists('s:loaded')
    finish
endif
let s:loaded = 1

let s:dCalltipsData = {}
let s:dCalltipsData.usePrevTags = 0 " 是否使用最近一次的 tags 缓存

"临时启用选项函数 {{{2
function! s:SetOpts()
    let s:bak_cot = &completeopt

    if g:VLOmniCpp_ItemSelectionMode == 0 " 不选择
        set completeopt-=menu,longest
        set completeopt+=menuone
    elseif g:VLOmniCpp_ItemSelectionMode == 1 " 选择并插入文本
        set completeopt-=menuone,longest
        set completeopt+=menu
    elseif g:VLOmniCpp_ItemSelectionMode == 2 " 选择但不插入文本
        set completeopt-=menu,longest
        set completeopt+=menuone
    else
        set completeopt-=menu
        set completeopt+=menuone,longest
    endif

    return ''
endfunction
function! s:RestoreOpts()
    if exists('s:bak_cot')
        let &completeopt = s:bak_cot
        unlet s:bak_cot
    else
        return ""
    endif

    let sRet = ""

    if pumvisible()
        if g:VLOmniCpp_ItemSelectionMode == 0 " 不选择
            let sRet = "\<C-p>"
        elseif g:VLOmniCpp_ItemSelectionMode == 1 " 选择并插入文本
            let sRet = ""
        elseif g:VLOmniCpp_ItemSelectionMode == 2 " 选择但不插入文本
            let sRet = "\<C-p>\<Down>"
        else
            let sRet = "\<Down>"
        endif
    endif

    return sRet
endfunction
function! s:CheckIfSetOpts()
    let sLine = getline('.')
    let nCol = col('.') - 1
    "若是成员补全，添加 longest
    if sLine[nCol-2:] =~ '->' || sLine[nCol-1:] =~ '\.' 
                \|| sLine[nCol-2:] =~ '::'
        call s:SetOpts()
    endif

    return ''
endfunction 


function! s:SID() " 获取脚本 ID，这个函数名不能变 {{{2
    return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfunction
let s:sid = s:SID()
function! s:GetSFuncRef(sFuncName) "获取局部于脚本的函数的引用 {{{2
    let sFuncName = a:sFuncName =~ '^s:' ? a:sFuncName[2:] : a:sFuncName
    return function('<SNR>'.s:sid.'_'.sFuncName)
endfunction


"}}}
" 生成带编号菜单选择列表
" NOTE: 第一项(即li[0])不会添加编号
function! s:GenerateMenuList(li) "{{{2
    let li = a:li
    let nLen = len(li)
    let lResult = []

    if nLen > 0
        call add(lResult, li[0])
        let l = len(string(nLen -1))
        let n = 1
        for str in li[1:]
            call add(lResult, printf('%*d. %s', l, n, str))
            let n += 1
        endfor
    endif

    return lResult
endfunction
"}}}
function! s:StartQucikCalltips() "{{{2
    let s:dCalltipsData.usePrevTags = 1
    call g:VLCalltips_Start()
    return ''
endfunction
"}}}
function! s:RequestCalltips(...) " 可选参数标识是否刚在补全后发出请求 {{{2
    let bUsePrevTags = a:0 > 0 ? a:1.usePrevTags : 0
    let s:dCalltipsData.usePrevTags = 0 " 清除这个标志
    if bUsePrevTags
    " 从全能补全菜单选择条目后，使用上次的输出
        let sLine = getline('.')
        let nCol = col('.')
        if sLine[nCol-3:] =~ '^()'
            let sFuncName = matchstr(sLine[: nCol-4], '\~\?\w\+$')
            if sFuncName[0] !=# '~'
                normal! h
                let lCalltips = s:GetCalltips(s:lTags, sFuncName)
                call g:VLCalltips_UnkeepCursor()
                return lCalltips
            endif
        endif

        return ''
    endif

    " 普通情况，请求 calltips
    " 确定函数括号开始的位置
    let lOrigCursor = getpos('.')
    " 返回 1 则跳过此匹配. 手册有误, 说返回 0 就跳过!
    if g:VLOmniCpp_EnableSyntaxTest
        " 跳过字符串中和注释中的匹配
        let sSkipExpr = 'synIDattr(synID(line("."), col("."), 0), "name") '
                    \. '=~? "character\\|string\\|comment"'
    else
        " 空则不跳过任何匹配
        let sSkipExpr = ''
    endif
    " 括号开始位置
    let lStartPos = searchpairpos('(', '', ')', 'nWb', sSkipExpr)
    "考虑刚好在括号内，加 'c' 参数
    let lEndPos = searchpairpos('(', '', ')', 'nWc', sSkipExpr)
    let lCurPos = lOrigCursor[1:2]

    "不在括号内
    if lStartPos == [0, 0]
        return ''
    endif

    let bImpossible = 0 " 不可能是 A<B> a(|);
    let bForceNew = 0   " 强制视为 new A<B>(|);

    "获取函数名称和名称开始的列，只能处理 '(' "与函数名称同行的情况，
    "允许之间有空格
    let sStartLine = getline(lStartPos[0])
    call cursor(lStartPos)
    let lTokens = omnicpp#utils#TokenizeStatementBeforeCursor()
    if empty(lTokens)
        return ''
    endif
    if lTokens[-1].value ==# '>'
        let bImpossible = 1
        let idx = 2
        let nLen = len(lTokens)
        let nDeep = 1
        while idx <= nLen
            let dToken = lTokens[-idx]
            if dToken.value ==# '>'
                let nDeep += 1
            elseif dToken.value ==# '<'
                let nDeep -= 1
            endif
            if nDeep == 0
                break
            endif
            let idx += 1
        endwhile
        let lTokens = lTokens[: -idx - 1]
    endif
    if empty(lTokens)
        return ''
    endif
    let sFuncName = lTokens[-1].value
    try
        if lTokens[-2].value ==# '~'
            let bImpossible = 1
            let sFuncName = '~' . sFuncName
        endif
    catch
    endtry
    let lFuncNameSPos = searchpos('\V' . sFuncName, 'bWn')
    let lFuncNameEPos = lFuncNameSPos[:]
    let lFuncNameEPos[1] += len(sFuncName)
    if lFuncNameSPos == [0, 0]
        return ''
    endif

    if !bImpossible
        " 检查是否 A<B> a(|); 形式
        try
            let bTest1 = 0 " 条件一:
            let bTest2 = 0 " 条件二:
            if lTokens[-1].kind == 'cppWord'
                let bTest1 = 1
            endif

            let lTmp = lTokens[:-2]
            if lTmp[-1].value ==# '>'
                " 剔除中间的 <>
                " eg. A<B> a(|);
                "      ^^^
                let bImpossible = 1
                let idx = 2
                let nLen = len(lTmp)
                let nDeep = 1
                while idx <= nLen
                    let dToken = lTmp[-idx]
                    if dToken.value ==# '>'
                        let nDeep += 1
                    elseif dToken.value ==# '<'
                        let nDeep -= 1
                    endif
                    if nDeep == 0
                        break
                    endif
                    let idx += 1
                endwhile
                let lTokens = lTmp[: -idx - 1] + [lTokens[-1]]
            endif

            if lTokens[-2].kind == 'cppWord'
                let bTest2 = 1
                call remove(lTokens, -1)
            endif

            if bTest1 && bTest2
                " 满足条件, 构造成 new A<B>(|)
                let bForceNew = 1
                let sFuncName = lTokens[-1].value
                let lFuncNameSPos = searchpos(sFuncName, 'bWn')
                let lFuncNameEPos = lFuncNameSPos[:]
                let lFuncNameEPos[1] += len(sFuncName)
            endif
        catch
        endtry
    endif

    let lCalltips = []
    if sFuncName != '' && sFuncName[0] !=# '~'
        " 找到了函数名，开始全能补全
        call cursor(lFuncNameEPos)
        let nStartCol = omnicpp#complete#Complete(1, '')
        call cursor(lFuncNameSPos)

        " 基本上免不了要使用 dScopeInfo，所以还是获取一次吧
        let lScopeStack = omnicpp#scopes#GetScopeStack()
        call extend(lScopeStack[0].nsinfo.usingns, 
                    \g:VLOmniCpp_PrependSearchScopes, 0)
        let dScopeInfo = omnicpp#resolvers#ResolveScopeStack(lScopeStack)

        " 用于支持 new CLS(|) 和 CLS cls(|) 形式的 calltips
        let dOmniInfo = omnicpp#resolvers#GetOmniInfo(s:lTokens)
        if has_key(dOmniInfo, 'new') || bForceNew
            " eg. A::B *c = new A::B(|);
            let dToken1 = {'kind': 'cppWord', 'value': sFuncName}
            let dToken2 = {'kind': 'cppOperatorPunctuator', 'value': '::'}
            call add(s:lTokens, dToken1)
            call add(s:lTokens, dToken2)
            " 必定是成员补全
            let s:nCompletionType = s:CompletionType_MemberCompl
            " NOTE: 如果 sFuncName 是一个 typedef, 需要展开
            " std::string::basic_string<char>(|)
            let dOmniInfo = omnicpp#resolvers#GetOmniInfo(s:lTokens)
            let lSearchScopes = omnicpp#resolvers#ResolveOmniInfo(
                        \lScopeStack, dOmniInfo)
            " 解析完毕的结果应该就是第一个搜索域
            let sFuncName = get(lSearchScopes, 0, sFuncName)
            let sFuncName = matchstr(sFuncName, '\w\+$')
        endif

        " NOTE: 这里已经能够支持在容器内基类的构造函数的 Calltips
        "       应该是搜索域的原因(刚好有基类的搜索域?)
        " eg. class B : A { A(|) }
        let lTags = omnicpp#complete#Complete(0, sFuncName)
        let lCalltips = s:GetCalltips(lTags, sFuncName)

        " 如果在类变量初始化列表中, 要支持变量的构造函数初始化
        if empty(lCalltips) 
                    \&& match(omnicpp#utils#GetCurStatementBeforeCursor(), 
                    \         ')\s*:') != -1
            " 确定在类变量初始化列表中
            let lSearchScopes = dScopeInfo.container + dScopeInfo.global 
                        \+ dScopeInfo.function
            let dTypeInfo = omnicpp#resolvers#ResolveFirstVariable(
                        \lSearchScopes, sFuncName)
            if !empty(dTypeInfo)
                " 修正 s:lTokens 来欺骗 omnicpp#complete#Complete()
                let lTmpTokens = omnicpp#tokenizer#Tokenize(
                            \dTypeInfo.name . '::')
                call extend(s:lTokens, lTmpTokens)

                " 修正补全类型来欺骗 omnicpp#complete#Complete()
                let s:nCompletionType = s:CompletionType_MemberCompl

                " 最紧要正确，这里的效率不算重要
                let dOmniInfo = omnicpp#resolvers#GetOmniInfo(s:lTokens)
                let lSearchScopes = omnicpp#resolvers#ResolveOmniInfo(
                            \lScopeStack, dOmniInfo)
                " 解析完毕的结果应该就是第一个搜索域
                let sFuncName = get(lSearchScopes, 0, sFuncName)
                let sFuncName = matchstr(sFuncName, '\w\+$')

                let lTags = omnicpp#complete#Complete(0, sFuncName)
                let lCalltips = s:GetCalltips(lTags, sFuncName)
            endif
        endif
    endif

    call setpos('.', lOrigCursor)
    "call g:DisplayVLCalltips(lCalltips, 0, 1)
    call g:VLCalltips_KeepCursor()

    return lCalltips
endfunction
"}}}
function! s:CanComplete() "{{{2
    if (getline('.') =~ '#\s*include')
        " 写头文件，忽略
        return 0
    else
        " 检测光标所在的位置，如果在注释、双引号、浮点数时，忽略
        let nLine = line('.')
        let nCol = col('.') - 1 " 是前一列 eg. ->|
        if nCol < 1
            " TODO: 支持续行的补全
            return 0
        endif
        if g:VLOmniCpp_EnableSyntaxTest
            let lStack = synstack(nLine, nCol)
            let lStack = empty(lStack) ? [] : lStack
            for nID in lStack
                if synIDattr(nID, 'name') 
                            \=~? 'comment\|string\|number\|float\|character'
                    return 0
                endif
            endfor
        else
            " TODO
        endif

        return 1
    endif
endfunction
"}}}
function! s:LaunchOmniCppCompletion() "{{{2
    if s:CanComplete()
        return "\<C-x>\<C-o>"
    else
        return ''
    endif
endfunction
"}}}
function! s:CompleteByChar(sChar) "{{{2
    if a:sChar ==# '.'
        return a:sChar . s:LaunchOmniCppCompletion()
    elseif a:sChar ==# '>'
        if getline('.')[col('.') - 2] != '-'
            return a:sChar
        else
            return a:sChar . s:LaunchOmniCppCompletion()
        endif
    elseif a:sChar ==# ':'
        if getline('.')[col('.') - 2] != ':'
            return a:sChar
        else
            return a:sChar . s:LaunchOmniCppCompletion()
        endif
    endif
endfunction
"}}}
function! omnicpp#complete#Init() "{{{2
    if !exists('g:VLWorkspaceHasStarted') || !g:VLWorkspaceHasStarted
        " 仅支持在 VimLite 中使用
        return ''
    endif

    " 初始化数据库
    call VimTagsManagerInit()

    " 初始化函数 Calltips 服务
    call g:VLCalltips_RegisterCallback(
                \s:GetSFuncRef('s:RequestCalltips'), s:dCalltipsData)
    call g:InitVLCalltips()

    " 初始化设置
    call omnicpp#settings#Init()

    "setlocal completefunc=
    setlocal omnifunc=omnicpp#complete#Complete

    " TODO: 不应该使用全局变量
    let g:dOCppNSAlias = {} " 名空间别名 {'abc': 'std'}
    let g:dOCppUsing = {} " using. eg. {'cout': 'std::out', 'cin': 'std::cin'}

    " 硬替换类型, 补全前修改为合适的值
    if !exists('g:dOCppTypes')
        let g:dOCppTypes = {}
    endif

    if g:VLOmniCpp_MayCompleteDot
        inoremap <silent> <buffer> . 
                    \<C-r>=<SID>SetOpts()<CR>
                    \<C-r>=<SID>CompleteByChar('.')<CR>
                    \<C-r>=<SID>RestoreOpts()<CR>
    endif

    if g:VLOmniCpp_MayCompleteArrow
        inoremap <silent> <buffer> > 
                    \<C-r>=<SID>SetOpts()<CR>
                    \<C-r>=<SID>CompleteByChar('>')<CR>
                    \<C-r>=<SID>RestoreOpts()<CR>
    endif

    if g:VLOmniCpp_MayCompleteColon
        inoremap <silent> <buffer> : 
                    \<C-r>=<SID>SetOpts()<CR>
                    \<C-r>=<SID>CompleteByChar(':')<CR>
                    \<C-r>=<SID>RestoreOpts()<CR>
    endif

    inoremap <script> <Plug>SmartComplete 
                \<C-r>=<SID>CheckIfSetOpts()<CR>
                \<C-r>=<SID>LaunchOmniCppCompletion()<CR>
                \<C-r>=<SID>RestoreOpts()<CR>

    " 显示函数 calltips 的快捷键
    if g:VLOmniCpp_MapReturnToDispCalltips
        inoremap <silent> <expr> <buffer> <CR> pumvisible() ? 
                    \"\<C-y><C-r>=<SID>StartQucikCalltips()\<Cr>" : 
                    \"\<CR>"
    endif

    if g:VLOmniCpp_ItemSelectionMode > 4
        imap <silent> <buffer> <C-n> <Plug>SmartComplete
    else
        "inoremap <silent> <buffer> <C-n> 
                    "\<C-r>=<SID>SetOpts()<CR>
                    "\<C-r>=<SID>LaunchOmniCppCompletion()<CR>
                    "\<C-r>=<SID>RestoreOpts()<CR>
    endif

    exec 'nnoremap <silent> <buffer> ' . g:VLOmniCpp_GotoDeclarationKey 
                \. ' :call omnicpp#complete#GotoDeclaration()<CR>'

    exec 'nnoremap <silent> <buffer> ' . g:VLOmniCpp_GotoImplementationKey 
                \. ' :call omnicpp#complete#SmartJump()<CR>'

endfunction
"}}}
function! s:GetCalltips(lTags, sFuncName) "{{{2
    let lTags = a:lTags
    let sFuncName = a:sFuncName

    let lCalltips = []
    for dTag in lTags
        if dTag.name ==# sFuncName 
            " 如果声明和定义分开, 只取声明的 tag
            " ctags 中, 解析类方法定义的时候是没有访问控制信息的
            " 1. 原型
            " 2. C 中的函数(kind == 'f', !has_key(dTag, 'class'))
            " 3. C++ 中的内联成员函数
            if dTag.kind ==# 'p' 
                        \|| (dTag.kind ==# 'f' && !has_key(dTag, 'class'))
                        \|| (dTag.kind ==# 'f' && has_key(dTag, 'class') 
                        \    && has_key(dTag, 'access'))
                let sName = dTag.path
                " 首先尝试在模式中查找限定词, 
                " 若查找失败才用 tag 中的 qualifiers 域, 因为这个域的解析不完善
                "let sText = dTag.text
                "let sText = matchstr(sText, '\C\s*\zs[^;]\{-}\ze' . sFuncName)
                "if sText ==# ''
                    "let sText = dTag.text . ' '
                "endif
                "if sText =~# '::\s*$'
                    "let sName = sFuncName
                "endif
                "call add(lCalltips, printf("%s%s%s", sText, 
                            "\              sName, dTag.signature))
                let sRetrun = get(dTag, 'return', '')
                call add(lCalltips, printf("%s %s%s", sRetrun, 
                            \              sName, dTag.signature))
            elseif dTag.kind ==# 'd' && has_key(dTag, 'signature')
                " 处理函数形式的宏
                call add(lCalltips, dTag.name . dTag.signature)
            endif
        endif
    endfor

    return lCalltips
endfunction
"}}}
" 跳转到 lTags 中的 tag 所在位置
function! s:GotoTagPosition(lTags) "{{{2
    let lResult = a:lTags
    if empty(lResult)
        return
    endif

    let dTag = lResult[0]

    if len(lResult) > 1
        " 弹出选择菜单
        let li = []
        for d in lResult
            call add(li, printf("%s, %s:%s",
                        \d.path . get(d, 'signature', ''),
                        \d.filename,
                        \d.line))
        endfor
        let nIdx = inputlist(s:GenerateMenuList(['Please select:'] + li)) - 1
        if nIdx >= 0 && nIdx < len(lResult)
            let dTag = lResult[nIdx]
        else
            return lResult
        endif
    endif

    let sSymbol = dTag.name
    let sFileName = dTag.filename
    let sLineNr = dTag.line

    " 开始跳转
    if bufnr(sFileName) == bufnr('%')
        " 跳转的是同一个缓冲区, 仅跳至指定的行号
        normal! m'
        exec sLineNr
    else
        let sCmd = printf('e +%s %s', sLineNr, fnameescape(sFileName))
        exec sCmd
    endif

    let sSearchFlag = 'cW'
    if dTag.parent ==# dTag.name
                \&& match(dTag.text,
                \       printf('\<%s\s*::\s*%s\>', dTag.name, dTag.name)) != -1
        " 构造函数, 添加附加搜索字符, 因为 |A::A
        let sSymbol = '\>::\s\*\zs' . sSymbol . '\>'
    else
        let sSymbol = '\<' . sSymbol . '\>'
    endif
    call search('\C\V'.sSymbol, sSearchFlag, line('.'))
endfunction
"}}}
function! s:GetGotoTags() "{{{2
    let sWord = expand('<cword>')
    let lOrigPos = getpos('.')
    let sLine = getline('.')
    let save_ic = &ignorecase
    set noignorecase

    if col('.') == 1 || (col('.') > 1 && sLine[col('.')-2] =~# '\W')
        if sLine[col('.')-1] ==# '~'
        " 为了支持光标放到 '~' 位置的析构函数. eg. class A { |~A(); }
            " 右移一格
            call cursor(line('.'), col('.') + 1)
        endif

        " 光标在第一列或者光标前面是空格或者 '~'
        " 右移一格
        call cursor(line('.'), col('.') + 1)
    endif
    let nStartCol = omnicpp#complete#Complete(1, '')
    let lTags = omnicpp#complete#Complete(0, sWord, 0)

    if empty(lTags)
        call setpos('.', lOrigPos)
        let &ignorecase = save_ic
        return []
    endif

    let nSpecialType = 0
    " 检查是否可能正在跳转构造函数或析构函数(这个变量理论上不可能为空)
    if s:lOCppScopeStack[-1].kind == 'container'
                \&& s:lOCppScopeStack[-1].name ==# sWord
        " TODO: 只能处理在 class 大括号内的情况,
        "       不能处理作用域限定的情况(A::~A)
        "       因为符号补全不支持析构函数符号补全
        " 三种可能
        " 1. 构造函数
        " 2. 析构函数
        " 3. 类类型 (eg. class A { A *pNext; })
        " 移动到单词的起始位置
        call search('\<', 'b', line('.'))
        " 先检查是否函数, 方法是检查后面跟不跟括号 '('
        let nRet = search(sWord . '\s*(', 'cn', line('.'))
        if nRet != 0
        " 搜索成功, 表示肯定是函数
            " 再检查是否析构函数, 方法是检查前面跟不跟 '~'
            let nRet = search('\~\s*'. sWord, 'bn', line('.'))
            if nRet == 0
            " 构造函数
                let nSpecialType = 1
            else
            " 析构函数
                let nSpecialType = 2
                let sWord = '~' . sWord
                " 重新搜索
                let lTags = g:GetOrderedTagsByScopesAndName(
                            \s:lSearchScopes, sWord, 0)
            endif
        else
        " 如果不是上面两种情况, 那基本可能确定是第三种情况, 类类型
            let nSpecialType = 3
        endif
    endif

    if nSpecialType == 1 || nSpecialType == 2
        " 过滤掉类型不是原型和函数的 tag
        call filter(lTags,
                    \'v:val["kind"][0] ==# "p" || v:val["kind"][0] ==# "f"')
    elseif nSpecialType == 3
        " 过滤掉类型是原型或者函数的 tag
        call filter(lTags,
                    \'!(v:val["kind"][0] ==# "p" || v:val["kind"][0] ==# "f")')
    endif

    call setpos('.', lOrigPos)
    let &ignorecase = save_ic

    return lTags
endfunction
"}}}
" 跳转到局部变量的声明/定义处
function! s:SearchLocalDecl() "{{{2
    let sWord = expand('<cword>')
    " 是光标前，a.|
    let lTokens = omnicpp#utils#TokenizeStatementBeforeCursor()
    let bSkipThis = 0
    if empty(lTokens)
        let bSkipThis = 0
    elseif lTokens[-1].value ==# '.' || lTokens[-1].value ==# '->'
    " 刚好在 '.' 后的情况
        let bSkipThis = 1
    elseif len(lTokens) >= 2 
                \&& (lTokens[-2].value ==# '.' || lTokens[-2].value ==# '->')
        let bSkipThis = 1
    endif

    let dTypeInfo = {'name': ''} " 伪装
    if !bSkipThis
        let dTypeInfo = omnicpp#resolvers#SearchLocalDecl(sWord, 1)
    endif
    if dTypeInfo.name !=# ''
        return [dTypeInfo]
    else
        return []
    endif
endfunction
"}}}
" 跳至符号声明处
function! omnicpp#complete#GotoDeclaration() "{{{2
    let lTags = []

    let lTags = s:SearchLocalDecl()
    if !empty(lTags)
        return lTags
    endif

    let lTags = s:GetGotoTags()
    if empty(lTags)
        return []
    endif

    let lResult = lTags

    if lTags[0].kind[0] ==# 'p' || lTags[0].kind[0] ==# 'f'
    " 请求跳转到函数的声明处
        " 不能简单地剔除 lTags 里面类型为 'f' 的项目,
        " 因为可能声明的时候就定义
        " {path: tag} -> 记录字典, tag.path 对应的 tag
        let d = {}
        for dTag in lResult
            " TODO: signature 的直接字符串比较并不可取
            let sSignature = get(dTag, 'signature', '()')
            let sKey = dTag.path . sSignature
            if !has_key(d, sKey)
                " 添加
                let d[sKey] = dTag
            else
                if d[sKey]['kind'][0] ==# 'f'
                    " 函数的声明和定义分开, 把定义剔除
                    let d[sKey] = dTag
                endif
            endif
        endfor

        let lResult = values(d)
    endif

    call s:GotoTagPosition(lResult)

    return lResult
endfunction
"}}}
" 跳至符号实现处
function! omnicpp#complete#GotoImplementation() "{{{2
    let lTags = []

    let lTags = s:SearchLocalDecl()
    if !empty(lTags)
        return lTags
    endif

    let lTags = s:GetGotoTags()
    if empty(lTags)
        return []
    endif

    let lResult = lTags

    if lTags[0].kind[0] ==# 'p' || lTags[0].kind[0] ==# 'f'
    " 请求跳转到函数的实现处
        " 剔除 lTags 里面类型为 'p' 的项目
        call filter(lResult, 'v:val["kind"][0] !=# "p"')
    else
    " 请求跳转到数据结构的实现处
        " 全部剔除纯声明式的数据结构。eg. struct a;
        call filter(lResult, 'v:val["kind"][0] !=# "x"')
    endif

    call s:GotoTagPosition(lResult)

    return lResult
endfunction
"}}}
" 智能跳转, 可跳转到包含的文件, 符号的实现处
function! omnicpp#complete#SmartJump() "{{{2
    let sLine = getline('.')
    if matchstr(sLine, '^\s*#\s*include') !=# ''
        " 跳转到包含的文件
        if exists(':VLWOpenIncludeFile') == 2
            VLWOpenIncludeFile
        endif
    else
        " 跳转到符号的实现处
        call omnicpp#complete#GotoImplementation()
    endif
endfunction
"}}}
" 作用域内符号补全, 即无任何限定作用域
" eg. prin|
let s:CompletionType_NormalCompl = 0
" 作用域内变量成员补全 ('::', '->', '.')
" eg. std::st|
let s:CompletionType_MemberCompl = 1
" 用于标识补全类型
let s:nCompletionType = s:CompletionType_NormalCompl
" 用于 omnifunc 第一阶段与第二阶段通讯, 指示禁止补全
let s:bDoNotComplete = 0
" 用于区分是否作用域操作符的成员补全
" 仅在 '作用域内变量成员补全' 时有用
let s:bIsScopeOperation = 0
" 当前语句的 token 列表
let s:lCurentStatementTokens = []
" omnifunc
" 可选参数控制是否允许 base 部分匹配(此时忽略大小写), 默认允许
function! omnicpp#complete#Complete(findstart, base, ...) "{{{2
    if a:findstart
        let s:nCompletionType = s:CompletionType_NormalCompl
        let s:bDoNotComplete = 0
        let s:bIsScopeOperation = 0
        "call vlutils#TimerStart() "计时用

        if mode() ==# 'i'
            let sLine = getline('.')[: col('.') - 2]
        else
            " 非插入模式下，光标所在的字符算在内，为了符号跳转
            let sLine = getline('.')[: col('.') - 1]
        endif

        " 跳过光标在注释和字符串中的补全请求
        if omnicpp#utils#IsCursorInCommentOrString()
            " BUG: 返回 -1 仍然进入下一阶段
            let s:bDoNotComplete = 1
            return -1
        endif

        " 基于 tokens 的预分析
        let lTokens = omnicpp#utils#TokenizeStatementBeforeCursor(1)

        let sCode = sLine[: -2] " 光标前的代码字符串
        if sCode =~# '^\s*#'
            " 预处理行
            if sCode =~# '^\s*#\s*include\>'
                " #include
                " TODO: include 文件补全
                let lTokens = []
            else
                " 非 #include
                let sCode = substitute(sCode, '^\s*#\s*\w\+\>', '', 'g')
                let lTokens = omnicpp#tokenizer#Tokenize(sCode)
            endif
        endif

        let s:lTokens = lTokens
        let b:lTokens = s:lTokens
        if empty(lTokens)
            " (1) 无预输入的作用域内符号补全不支持, 因为可能太多符号
            let s:bDoNotComplete = 1
            return -1
        endif

        if lTokens[-1].kind == 'cppKeyword' || lTokens[-1].kind == 'cppWord'
            " 肯定是有预输入的补全, 至于是不是成员补全需要进一步分析
            let s:lTokens = lTokens[:-2]
            let b:lTokens = s:lTokens

            if  sLine[-1:-1] =~# '\s' || sLine[-1:-1] ==# ''
                " 有预输入, 但是光标不邻接单词, 不能补全
                let s:bDoNotComplete = 1
                return -1
            endif

            if len(lTokens) >= 2 && lTokens[-2].value =~# '\.\|->\|::'
                if lTokens[-2].value ==# '::'
                    let s:bIsScopeOperation = 1
                else
                    let s:bIsScopeOperation = 0
                endif
                " (3) 有预输入的成员补全
                let s:nCompletionType = s:CompletionType_MemberCompl
            else
                " (2) 有预输入的作用域内符号补全
                let s:nCompletionType = s:CompletionType_NormalCompl
            endif

            let nRet = searchpos('\C' . lTokens[-1].value, 'Wbn')[1]
            let b:fs = nRet
            " BUG: 居然要减一才工作
            return nRet - 1
        elseif lTokens[-1].value =~# '\.\|->\|::'
            " (4) 无预输入的成员补全
            let s:nCompletionType = s:CompletionType_MemberCompl
            if lTokens[-1].value ==# '::'
                let s:bIsScopeOperation = 1
            else
                let s:bIsScopeOperation = 0
            endif

            let b:fs = col('.')
            return col('.')
        else
            let s:bDoNotComplete = 1
            return -1
        endif
    endif

    let lResult = []

    if s:bDoNotComplete
        let s:bDoNotComplete = 0
        return lResult
    endif

    let sBase = a:base
    let b:base = a:base
    let b:findstart = col('.')
    let bPartialMatch = a:0 > 0 ? a:1 : 1

    let lScopeStack = omnicpp#scopes#GetScopeStack()
    call extend(lScopeStack[0].nsinfo.usingns, 
                \g:VLOmniCpp_PrependSearchScopes, 0)
    " 设置全局变量, 用于 GetStopPosForLocalDeclSearch() 里面使用...
    let g:lOCppScopeStack = lScopeStack 
    " 本脚本使用的变量, 一直保存最近一次调用时保存的信息
    " 主要是为了那一点效率, 如果不需要那一点效率的话, 直接调用上述函数即可
    let s:lOCppScopeStack = lScopeStack
    "let lSimpleSS = omnicpp#complete#SimplifyScopeStack(lScopeStack)
    let lSearchScopes = []
    let lTags = []

    if s:nCompletionType == s:CompletionType_NormalCompl
        " (1) 作用域内非成员补全模式

        let dScopeInfo = omnicpp#resolvers#ResolveScopeStack(lScopeStack)
        let lSearchScopes = dScopeInfo.container + dScopeInfo.global 
                    \+ dScopeInfo.function
        call extend(lSearchScopes, g:VLOmniCpp_PrependSearchScopes, 0)
    else
        " (2) 作用域内成员补全模式

        let dOmniInfo = omnicpp#resolvers#GetOmniInfo(s:lTokens)
        if empty(dOmniInfo.omniss) && dOmniInfo.precast ==# '<global>'
                    \&& sBase ==# ''
            " 禁用全局全符号补全, 因为会卡
            return []
        endif

        let lSearchScopes = omnicpp#resolvers#ResolveOmniInfo(
                    \lScopeStack, dOmniInfo)
        "let b:dOmniInfo = dOmniInfo
    endif

    " 本脚本共用
    let s:lSearchScopes = lSearchScopes

    if !empty(lSearchScopes)
        " NOTE: lTags 列表的上限一般情况下是 1000, 所以会发现有时候符号不全
        "let lTags = g:GetTagsByScopesAndName(
                    "\lSearchScopes, sBase, bPartialMatch)
        " TODO: 需要展开 lSearchScopes，例如某个项目是一个派生类
        let lTags = g:GetOrderedTagsByScopesAndName(
                    \lSearchScopes, sBase, bPartialMatch)
        if !s:bIsScopeOperation 
                    \&& s:nCompletionType == s:CompletionType_MemberCompl
            " 过滤类型定义, 结构, 类
            call map(lTags, 's:ExtendTagToPopupMenuItem(v:val, "t", "s", "c")')
        else
            call map(lTags, 's:ExtendTagToPopupMenuItem(v:val)')
        endif
    endif

    " 添加 using 声明和名空间别名的名字
    if s:nCompletionType == s:CompletionType_NormalCompl
        for sName in keys(g:dOCppUsing)
            if sName =~ '^' . sBase
                let dItem = {}
                let dItem.word = sName
                let dItem.abbr = sName
                let dItem.menu = '  <using>'
                let dItem.kind = 'x'
                let dItem.icase = &ic
                let dItem.dup = 0
                call add(lTags, dItem)
            endif
        endfor

        for sName in keys(g:dOCppNSAlias)
            if sName =~ '^' . sBase
                let dItem = {}
                let dItem.word = sName
                let dItem.abbr = sName
                let dItem.menu = '  <nsalias>'
                let dItem.kind = 'n'
                let dItem.icase = &ic
                let dItem.dup = 0
                call add(lTags, dItem)
            endif
        endfor
    endif

    let lResult = lTags
    let s:lTags = lTags

    " 调试用
    "let b:lSearchScopes = lSearchScopes
    "let b:lTags = lTags

    unlet g:lOCppScopeStack
    "call vlutils#TimerEndEcho() " 计时用

    return lResult
endfunc
"}}}
" 简化 ScopeStack, scope.kind 为 'other' 的合并进前一个 scope
" 返回的是副本
function! omnicpp#complete#SimplifyScopeStack(lScopeStack) "{{{2
    let lResult = []
    for dScope in a:lScopeStack
        if dScope.kind == 'other'
            let dPrevScope = lResult[-1]
            let dPrevScope.namespaces += dScope.namespaces
            let dPrevScope.includes += dScope.namespaces
        else
            call add(lResult, copy(dScope))
        endif
    endfor

    return lResult
endfunc
"}}}
" Extend a tag entry to a popup entry
" 从 tag 字典生成补全字典(用于补全条目), 并把结果存在 tag 字典中(key 不重复?)
" 可选参数控制需要过滤的类型
function! s:ExtendTagToPopupMenuItem(dTag, ...) "{{{2
    let dTag = a:dTag
    let lFilterKinds = a:000

    " 过滤特定的类型
    if index(lFilterKinds, dTag.kind) >= 0
        return dTag
    endif

    if dTag.kind == 'f' && has_key(dTag, 'class') && !has_key(dTag, 'access')
        " 如此 tag 为类的成员函数, 类型为函数, 且没有访问控制信息, 跳过
        " 防止没有访问控制信息的类成员函数条目覆盖带访问控制信息的成员函数原型的
        return dTag
    endif

    " Add the access
    let sMenu = ''
    let dAccessChar = {'public': '+','protected': '#','private': '-'}
    if 1
        if has_key(dTag, 'access') && has_key(dAccessChar, dTag.access)
            let sMenu = sMenu.dAccessChar[dTag.access]
        else
            let sMenu = sMenu." "
        endif
    endif

    " Formating optional menu string we extract the scope information
    let sName = dTag.name
    let sWord = sName
    let sAbbr = sName

    if 1
        let sMenu = sMenu . ' ' . dTag.parent
    endif

    " Formating information for the preview window
    if index(['f', 'p'], dTag.kind[0]) >= 0
        if 0 && has_key(dTag, 'signature')
            let sAbbr .= dTag.signature
        else
            let sWord .= '()'
            let sAbbr .= '()'
        endif
    endif

    " 把函数形式的宏视为函数
    if dTag.kind[0] ==# 'd'
        let sString = dTag.text
        let sSignature = matchstr(sString, dTag.name . '\zs(.\{-1,})\ze')
        if sSignature !=# ''
            let dTag.signature = sSignature
            let sWord .= '()'
            let sAbbr .= '()'
        endif
    endif

    let sInfo = ''

    " If a function is a ctor we add a new key in the tag
    " 构造函数处理, 以及友元处理
    "if index(['f', 'p'], dTag.kind[0]) >= 0
        "if match(sName, '^\~') < 0 && a:szTypeName =~ '\C\<'.sName.'$'
            " It's a ctor
            "let dTag['ctor'] = 1
        "elseif has_key(dTag, 'access') && dTag.access == 'friend'
            " Friend function
            "let dTag['friendfunc'] = 1
        "endif
    "endif

    " Extending the tag item to a popup item
    let dTag['word']     = sWord
    let dTag['abbr']     = sAbbr
    let dTag['menu']     = sMenu
    let dTag['info']     = sInfo
    let dTag['icase']    = &ignorecase
    let dTag['dup']      = 0
    "let dTag['dup'] = (s:hasPreviewWindow 
                "\&& index(['f', 'p', 'm'], dTag.kind[0]) >= 0)
    return dTag
endfunc
"}}}
" vim:fdm=marker:fen:et:sts=4:fdl=1:
