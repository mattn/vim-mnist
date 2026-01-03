let s:grid_width = 56
let s:grid_height = 28

let s:drawing = {}
let s:is_inference_mode = v:false
let s:mnist_model_file = expand('<sfile>:h:h:p') .. '/mnist_model.json'

function! draw_mnist#start() abort
  if !filereadable(s:mnist_model_file)
    echoerr "Model file not found: " s:mnist_model_file
    return
  endif

  let s:ff = brain#load_model(s:mnist_model_file)
  let s:is_inference_mode = v:true

  vnew
  setlocal buftype=nofile
  setlocal bufhidden=wipe
  setlocal noswapfile
  setlocal modifiable
  setlocal filetype=mnist
  setlocal nocursorline
  setlocal nocursorcolumn
  setlocal norelativenumber
  setlocal number
  setlocal wrap
  setlocal signcolumn=no

  set mouse=n
  set mousemodel=extend
  set selectmode=

  call s:init_grid()

  nnoremap <buffer> <LeftMouse> <LeftMouse>:call <SID>on_mouse_click()<CR>
  nnoremap <buffer> <LeftDrag> :call <SID>on_mouse_click()<CR>
  inoremap <buffer> <LeftMouse> <Esc><LeftMouse>:call <SID>on_mouse_click()<CR>a

  nnoremap <buffer> <Space> :call <SID>toggle_pixel()<CR>
  nnoremap <buffer> <CR> :call <SID>run_inference()<CR>
  inoremap <buffer> <Space> <Esc>:call <SID>toggle_pixel()<CR>a
  inoremap <buffer> <CR> <Esc>:call <SID>run_inference()<CR>a

  vnoremap <buffer> <CR> :call <SID>fill_selection()<CR>
  vnoremap <buffer> <Esc> :call <SID>erase_selection()<CR>

  augroup MnistDrawing
    autocmd!
    autocmd BufLeave <buffer> call s:stop()
  augroup END

  echo "MNIST Inference Mode (gVim only)"
  echo "===================================="
  echo "Drawing:"
  echo "  Mouse drag: Free draw"
  echo "  Space key: Toggle pixel (arrow navigation)"
  echo "  v for selection -> Enter: Fill"
  echo "  v for selection -> Esc: Erase"
  echo ""
  echo "Inference:"
  echo "  Enter: Run inference"
  echo ""
  echo "Other:"
  echo "  c: Clear, q: Quit"
  echo "===================================="
endfunction

function! s:init_grid() abort
  call setline(1, repeat([''], s:grid_height))
  for l:y in range(s:grid_height)
    let l:line = repeat('.', s:grid_width)
    call setline(l:y + 1, l:line)
  endfor
endfunction

function! s:on_mouse_click() abort
  let l:pos = getmousepos()
  if l:pos.line < 1 || l:pos.line > s:grid_height
    return
  endif
  if l:pos.column < 1 || l:pos.column > s:grid_width
    return
  endif
  call s:draw_pixel(l:pos.line, l:pos.column)
endfunction

function! s:draw_pixel(line, col) abort
  let l:line_text = getline(a:line)
  if len(l:line_text) >= a:col
    let l:new_line = l:line_text[:a:col-2] . 'X' . l:line_text[a:col:]
    call setline(a:line, l:new_line)
  endif
endfunction

function! s:erase_pixel(line, col) abort
  let l:line_text = getline(a:line)
  if len(l:line_text) >= a:col
    let l:new_line = l:line_text[:a:col-2] . '.' . l:line_text[a:col:]
    call setline(a:line, l:new_line)
  endif
endfunction

function! s:toggle_pixel() abort
  let l:line = line('.')
  let l:col = col('.')
  if l:line < 1 || l:line > s:grid_height
    return
  endif
  if l:col < 1 || l:col > s:grid_width
    return
  endif
  let l:line_text = getline(l:line)
  if l:col <= len(l:line_text)
    if l:line_text[l:col-1] == 'X'
      call s:erase_pixel(l:line, l:col)
    else
      call s:draw_pixel(l:line, l:col)
    endif
  endif
  if l:col < s:grid_width
    normal! l
  elseif l:line < s:grid_height
    normal! j
    normal! 0
  endif
endfunction

function! s:fill_selection() abort
  let [l:line1, l:col1] = getpos("'<")[1:2]
  let [l:line2, l:col2] = getpos("'>")[1:2]
  if l:line1 > l:line2
    let l:temp = l:line1 | let l:line1 = l:line2 | let l:line2 = l:temp
  endif
  if l:col1 > l:col2
    let l:temp = l:col1 | let l:col1 = l:col2 | let l:col2 = l:temp
  endif
  for l:line in range(l:line1, l:line2)
    let l:line_text = getline(l:line)
    let l:start_col = l:col1 - 1
    let l:end_col = min([l:col2, len(l:line_text)])
    if l:start_col < len(l:line_text)
      let l:new_line = l:line_text[:l:start_col-1] . repeat('X', l:end_col - l:start_col) . l:line_text[l:end_col:]
      call setline(l:line, l:new_line)
    endif
  endfor
  normal! <Esc>
  call cursor(l:line2, l:col2)
endfunction

function! s:erase_selection() abort
  let [l:line1, l:col1] = getpos("'<")[1:2]
  let [l:line2, l:col2] = getpos("'>")[1:2]
  if l:line1 > l:line2
    let l:temp = l:line1 | let l:line1 = l:line2 | let l:line2 = l:temp
  endif
  if l:col1 > l:col2
    let l:temp = l:col1 | let l:col1 = l:col2 | let l:col2 = l:temp
  endif
  for l:line in range(l:line1, l:line2)
    let l:line_text = getline(l:line)
    let l:start_col = l:col1 - 1
    let l:end_col = min([l:col2, len(l:line_text)])
    if l:start_col < len(l:line_text)
      let l:new_line = l:line_text[:l:start_col-1] . repeat('.', l:end_col - l:start_col) . l:line_text[l:end_col:]
      call setline(l:line, l:new_line)
    endif
  endfor
  normal! <Esc>
endfunction

function! s:run_inference() abort
  if !s:is_inference_mode
    return
  endif
  let l:pixels = s:collect_pixels()
  let l:drawn_pixels = filter(deepcopy(l:pixels), 'v:val > 0')
  if len(l:drawn_pixels) < 5
    echo "Drawing is too empty. Please draw more."
    return
  endif
  call s:inference(l:pixels)
endfunction

function! s:collect_pixels() abort
  let l:pixels = []
  let l:drawn_count = 0
  
  for l:line_num in reverse(range(1, s:grid_height))
    let l:line = getline(l:line_num)
    
    for l:col_num in range(1, s:grid_width, 2)
      let l:pixel_val = 0
      
      for l:offset in [0, 1]
        let l:col_check = l:col_num + l:offset
        if l:col_check <= len(l:line)
          let l:char = l:line[l:col_check-1]
          if l:char == 'X'
            let l:pixel_val = 255
          endif
        endif
      endfor
      
      if l:pixel_val > 0
        let l:drawn_count = l:drawn_count + 1
      endif
      
      call add(l:pixels, l:pixel_val)
    endfor
  endfor
  
  echo "Collected pixels: " len(l:pixels) " (drawn: " l:drawn_count ")"
  return l:pixels
endfunction

function! s:inference(pixels) abort
  echo "Running inference..."
  let l:inputs = map(a:pixels, 'str2float(v:val) / 255.0')
  echo "Inputs length: " len(l:inputs) ", Expected: " s:ff.NInputs-1
  let l:outputs = s:ff.Update(l:inputs)
  let l:max_val = l:outputs[0]
  let l:max_idx = 0
  for l:i in range(1, 9)
    if l:outputs[l:i] > l:max_val
      let l:max_val = l:outputs[l:i]
      let l:max_idx = l:i
    endif
  endfor
  echo "\n"
  echo "=========================================="
  echo "Prediction: " l:max_idx
  echo "=========================================="
  echo "\nProbabilities:"
  for l:i in range(10)
    echo printf("  %d: %.4f", l:i, l:outputs[l:i])
  endfor
  echo "=========================================="
  echo "\nPress Enter to run inference again"
  echo "c: Clear, q: Quit"
endfunction

function! draw_mnist#stop() abort
  let s:is_inference_mode = v:false
  augroup MnistDrawing
    autocmd!
  augroup END
endfunction

function! draw_mnist#clear() abort
  for l:y in range(s:grid_height)
    call setline(l:y + 1, repeat('.', s:grid_width))
  endfor
endfunction
