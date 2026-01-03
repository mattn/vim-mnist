runtime! autoload/brain.vim

call brain#srand(0)

let s:ff = brain#new_feed()
call s:ff.Init(784, 200, 10)

let s:lines = split(system('gzip -dc mnist_train.csv.gz'), '\n')

function! s:parse_patterns(lines, max_samples) abort
  let l:patterns = []
  let l:max = a:max_samples > 0 ? min(a:max_samples, len(a:lines)) : len(a:lines)
  
  for l:i in range(l:max)
    let l:line = a:lines[l:i]
    let l:parts = split(l:line, ',')
    let l:label = str2nr(l:parts[0])
    let l:inputs = map(l:parts[1:], 'str2float(v:val) / 255.0')
    let l:output = repeat([0.0], 10)
    let l:output[l:label] = 1.0
    
    call add(l:patterns, [l:inputs, l:output])
  endfor
  
  return l:patterns
endfunction

echo "Parsing training data..."
let s:patterns = s:parse_patterns(s:lines, 5000)
echo "Training with" len(s:patterns) "samples..."

" Train the network
" iterations: number of epochs
" lRate: learning rate
" mFactor: momentum factor
" debug: show progress
call s:ff.Train(s:patterns, 50, 0.3, 0.1, v:true)

" Save model to JSON
function! s:save_model(ff, filename) abort
  call writefile([json_encode(a:ff)], a:filename)
endfunction

echo "Saving model..."
call s:save_model(s:ff, 'mnist_model.json')

echo ""
echo "Testing with first 10 samples..."
let s:test_patterns = s:patterns[:9]
call s:ff.Test(s:test_patterns)
