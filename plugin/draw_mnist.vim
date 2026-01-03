command! StartMnist call draw_mnist#start()

autocmd FileType mnist nnoremap <buffer> q :call draw_mnist#stop()<CR>:bw!<CR>
autocmd FileType mnist nnoremap <buffer> c :call draw_mnist#clear()<CR>
