" Python indent file
" Language:	    Python
" Maintainer:	    Eric Mc Sween <em@tomcom.de>
" Original Author:  David Bustos <bustos@caltech.edu> 
" Last Change:      2004 Apr 26 

" Only load this indent file when no other was loaded.
if exists("b:did_indent")
    finish
endif
let b:did_indent = 1

setlocal expandtab
setlocal nolisp
setlocal autoindent
setlocal indentexpr=GetPythonIndent(v:lnum)
setlocal indentkeys+=<:>,=elif,=except

let s:maxoff = 50

" Find backwards the closest open parenthesis/bracket/brace.
function! s:SearchParensPair()
    let line = line('.')
    let col = col('.')
    
    " Skip strings and comments and don't look too far
    let skip = "line('.') < " . (line - s:maxoff) . " ? dummy :" .
                \ 'synIDattr(synID(line("."), col("."), 0), "name") =~? ' .
                \ '"string\|comment"'

    " Search for parentheses
    call cursor(line, col)
    let parlnum = searchpair('(', '', ')', 'bW', skip)
    let parcol = col('.')

    " Search for brackets
    call cursor(line, col)
    let par2lnum = searchpair('\[', '', '\]', 'bW', skip)
    let par2col = col('.')

    " Search for braces
    call cursor(line, col)
    let par3lnum = searchpair('{', '', '}', 'bW', skip)
    let par3col = col('.')

    " Get the closest match
    if par2lnum > parlnum || (par2lnum == parlnum && par2col > parcol)
        let parlnum = par2lnum
        let parcol = par2col
    endif
    if par3lnum > parlnum || (par3lnum == parlnum && par3col > parcol)
        let parlnum = par3lnum
        let parcol = par3col
    endif 

    " Put the cursor on the match
    if parlnum > 0
        call cursor(parlnum, parcol)
    endif
    return parlnum
endfunction

function! s:StatementStart(lnum)
    let lnum = a:lnum
    while 1
        if getline(lnum - 1) =~ '\\$'
            let lnum = lnum - 1
        else
            call cursor(lnum, 1)
            let maybe_lnum = s:SearchParensPair()
            if maybe_lnum < 1
                return lnum
            else
                let lnum = maybe_lnum
            endif
        endif
    endwhile
endfunction

function! GetPythonIndent(lnum)

    " First line has indent 0
    if a:lnum == 1
        return 0
    endif
    
    " If the previous line was blank, do nothing.
    let pline = getline(a:lnum - 1)
    if pline =~ '^\s*$'
        return -1
    endif
    
    " If we can find an open parenthesis/bracket/brace, align with it.
    call cursor(a:lnum, 1)
    let parlnum = s:SearchParensPair()
    if parlnum > 0
        return col('.')
    endif

    let sslnum = s:StatementStart(a:lnum - 1)
    
    " If this line is explicitly joined, try to find an indentation that looks
    " good. 
    if pline =~ '\\$'
        let compound_statement = '^\s*\(if\|while\|for\s.*\sin\|except\)\s*'
        let maybe_indent = matchend(getline(sslnum), compound_statement)
        if maybe_indent != -1
            return maybe_indent
        else
            return indent(sslnum) + &sw * 2
        endif
    endif
        
    " If the previous line ended with a colon, indent relative to
    " statement start.
    if pline =~ ':\s*$'
        return indent(sslnum) + &sw
    endif

    " If the previous line was a stop-execution statement...
    if getline(sslnum) =~ '^\s*\(break\|continue\|raise\|return\)\>'
        " See if the user has already dedented
        if indent(a:lnum) > indent(sslnum) - &sw
            " If not, recommend one dedent
            return indent(sslnum) - &sw
        endif
        " Otherwise, trust the user
        return -1
    endif

    return indent(sslnum)
endfunction
