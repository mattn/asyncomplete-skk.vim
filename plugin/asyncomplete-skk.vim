augroup asyncomplete-skk-setup
  au!
  au User asyncomplete_setup call asyncomplete#sources#skk#init()
augroup END

inoremap <plug>(asyncomplete-skk-toggle) <c-r>=asyncomplete#sources#skk#toggle()<cr>
