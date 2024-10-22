highlight HNTitle ctermfg=208 guifg=#ff6600
syn match HNTitle /^┌───┐$/
syn match HNTitle /^│ Y │.*$/
syn match HNTitle /^└───┘*$/

set conceallevel=3
syn match Conceal /\s\[[0-9]\{3,}\]$/ conceal
syn match Conceal /\s\[http.\+\]$/ conceal

syn match Comment /^\s\?[0-9]\{1,2}\./
syn match Comment /\s([^()]*)\s\[/ contains=Conceal
syn match Comment /^\s\{0,4}.*ago\(.*comment.*\[\|$\)/ contains=Conceal
syn match Comment /^\s*.*ago\s\[/ contains=Conceal
