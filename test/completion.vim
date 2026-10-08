set nocompatible
set viminfo=
set noswapfile
set completeopt=menuone,noselect
set expandtab shiftwidth=2
execute 'set runtimepath^=' . fnameescape($CONTEXT_FILETYPE_RTP)
execute 'set runtimepath^=' . fnameescape($NEOSNIPPET_RTP)
execute 'set runtimepath^=' . fnameescape($VIM_LSP_RTP)
execute 'set runtimepath^=' . fnameescape($ADAPTER_RTP)
let g:neosnippet#disable_runtime_snippets = {'_': 1}
let g:neosnippet#disable_select_mode_mappings = 0
let g:neosnippet#enable_complete_done = 0
runtime plugin/neosnippet.vim
runtime plugin/lsp.vim
runtime plugin/lsp_neosnippet.vim
imap <C-k> <Plug>(neosnippet_expand_or_jump)
smap <C-k> <Plug>(neosnippet_expand_or_jump)
let s:fixture = expand('<sfile>:p:h')
if $COMPLETION_METHOD ==# 'omni'
call lsp#register_server({
            \ 'name': 'fixture',
            \ 'cmd': {info -> [$PYTHON, s:fixture . '/server.py', $SNIPPET_FILE]},
            \ 'allowlist': ['fixture'],
            \ })
endif
function! TestExpand() abort
    call lsp_neosnippet#expand_snippet({'snippet': json_decode(join(readfile($SNIPPET_FILE), "\n"))})
    return ''
endfunction
execute 'silent edit ' . fnameescape($BUFFER_FILE)
setfiletype fixture
setlocal omnifunc=lsp#complete
call setline(1, $PREFIX)
call cursor(1, strlen($PREFIX) + 1)
let s:phase = 0
let s:ticks = 0
let s:initial = {}
function! s:tick(timer) abort
    let s:ticks += 1
    if s:phase == 0 && $COMPLETION_METHOD ==# 'direct'
        call feedkeys("A\<C-r>=TestExpand()\<CR>", 't')
        let s:phase = 2
        let s:ticks = 0
    elseif s:phase == 0 && s:ticks > 10 && lsp#get_server_status('fixture') ==# 'running'
        call feedkeys("A\<C-x>\<C-o>", 't')
        let s:phase = 1
    elseif s:phase == 1 && pumvisible()
        call feedkeys("\<C-n>\<C-y>", 't')
        let s:phase = 2
        let s:ticks = 0
    elseif s:phase == 2 && s:ticks > 5
        let s:initial = {'lines': getline(1, '$'), 'cursor': getpos('.')[1:2], 'mode': mode()}
        call feedkeys("\<C-k>\<C-k>", 't')
        let s:phase = 3
        let s:ticks = 0
    elseif s:phase == 3 && s:ticks > 5
        call writefile([json_encode({'initial': s:initial, 'lines': getline(1, '$'), 'error': v:errmsg})], $RESULT_FILE)
        call timer_stop(a:timer)
        call feedkeys("\<Esc>:qa!\<CR>", 't')
    elseif s:ticks > 200
        call writefile([json_encode({'timeout': s:phase, 'status': lsp#get_server_status('fixture'), 'error': v:errmsg})], $RESULT_FILE)
        call timer_stop(a:timer)
        call feedkeys("\<Esc>:qa!\<CR>", 't')
    endif
endfunction
call timer_start(20, function('s:tick'), {'repeat': -1})
