function! s:convert_token(token) abort
    if a:token ==# '\}'
        return '}'
    elseif a:token =~# '^\$\d\+$'
        return '${' . a:token[1:] . '}'
    endif
    " LSP backticks are literal, not Neosnippet expressions.
    return substitute(a:token, '`', '\\`', 'g')
endfunction

function! s:escape_snippet(text) abort
    " Keep escaped dollars and placeholder defaults intact for Neosnippet.
    let l:token = '\\.\|\${\d\+\%(:\%(\\.\|[^}]\)*\)\?}\|\$\d\+\|`'
    let l:snippet = substitute(a:text, l:token, '\=s:convert_token(submatch(0))', 'g')
    if l:snippet !~# '\%(\\\@<!\|\\\\\zs\)\${0}$'
        let l:snippet .= '${0}'
    endif
    return l:snippet
endfunction

function! lsp_neosnippet#expand_snippet(params) abort
    let l:snippet = s:escape_snippet(a:params.snippet)
    let [l:cur_text, l:col, l:expr] = neosnippet#mappings#_pre_trigger()
    " anonymous() also embeds literal newlines in commands; serialize both arguments.
    let l:expr .= printf("\<C-c>:call neosnippet#view#_insert(%s, {'lspitem': v:true}, %s, %d)\<CR>",
                \ json_encode(l:snippet), json_encode(l:cur_text), l:col)
    call feedkeys(l:expr, 'n')
endfunction
