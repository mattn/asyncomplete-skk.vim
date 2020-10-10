if exists('g:asyncomplete_skk_loaded')
    finish
endif
let g:asyncomplete_skk_loaded = 1

let s:enable = 0
let s:base = ''
let s:startcol = -1

function! s:handle_stdout(opt, ctx, job_id, data, event_type) abort
  let l:resp = json_decode(filter(a:data, {k, v -> !empty(v)})[-1])
  let l:matches = map(copy(l:resp.result), {k, v -> {
      \ 'menu': 'skk',
      \ 'word': trim(v),
      \ 'abbr': trim(v),
      \ 'icase': 1,
      \ 'dup': 0,
      \ }})
  let a:ctx['lnum'] = getcurpos()[1]
  let a:ctx['col'] = getcurpos()[2]
  call asyncomplete#complete(a:opt['name'], a:ctx, s:startcol, l:matches)
endfunction

function! s:completor(opt, ctx) abort
  if !s:enable
    return
  endif
  if !has_key(s:, 'jobid')
    let s:jobid = async#job#start(['skk-cli', '-json'], {
    \ 'on_stdout': function('s:handle_stdout', [a:opt, a:ctx]),
    \ })
  endif
  let l:typed = a:ctx['typed']
  let l:typed = getline('.')
  let l:startcol = match(l:typed, '[a-zA-Z]\+$')
  if l:startcol == -1
    return
  endif
  let l:base = getline('.')[l:startcol : col('.')]
  let s:startcol = l:startcol
  call async#job#send(s:jobid, json_encode(#{text: l:base}) .. "\n")
endfunction

function! s:filter(matches, startcol, base) abort
  let l:matches = a:matches
  let l:startcol = a:startcol
  let l:base = a:base
  let l:startcols = []
  let l:items = []
  for l:item in l:matches['items']
    let l:startcols += [l:startcol+1]
    call add(l:items, l:item)
  endfor
  return [l:items, l:startcols]
endfunction

function! s:triggers() abort
  return sort(map(range(char2nr('a'), char2nr('z')), {k, v -> nr2char(v)}) + map(range(char2nr('A'), char2nr('Z')), {k, v -> nr2char(v)}))
endfunction

function! asyncomplete#sources#skk#disable() abort
  let s:enable = 0
endfunction

function! asyncomplete#sources#skk#enable() abort
  let s:enable = 1
endfunction

function! asyncomplete#sources#skk#status() abort
  return s:status
endfunction

function! asyncomplete#sources#skk#toggle() abort
  let s:enable = !s:enable
  return ''
endfunction

function! asyncomplete#sources#skk#init() abort
  call asyncomplete#register_source({
  \ 'name': 'skk',
  \ 'allowlist': ['*'],
  \ 'priority': 10,
  \ 'completor': function('s:completor'),
  \ 'filter': function('s:filter'),
  \ 'refresh_pattern': '\(.$)',
  \ 'triggers': {'*': s:triggers()},
  \ })
endfunction
