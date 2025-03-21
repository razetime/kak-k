# Kak highlighting for k
# based on:
# - https://codeberg.org/ngn/k/src/branch/master/vim-k/syntax/k.vim
# - https://github.com/mlochbaum/BQN/blob/master/editors/kak/autoload/filetype/bqn.kak

hook global BufCreate .*\.k %{
    set-option buffer filetype k
    set-option buffer matching_pairs ( ) { } [ ]
}

# Initialization
# ‾‾‾‾‾‾‾‾‾‾‾‾‾‾

declare-option str k_exec "~/k/k" 
hook global WinSetOption filetype=k %¹
    require-module k

    hook window InsertChar \n -group k-indent k-indent-on-new-line
    hook window InsertChar [}⟩\]] -group k-indent k-indent-on-closing

    hook -once -always window WinSetOption filetype=.* %{ remove-hooks window k-.+ }
¹

hook -group k-highlight global WinSetOption filetype=k %{
    add-highlighter window/k ref k
    hook -once -always window WinSetOption filetype=.* %{ remove-highlighter window/k }
}

provide-module k %¹

# Highlighters & Completion
# ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
add-highlighter shared/k regions
add-highlighter shared/k/code default-region group
add-highlighter shared/k/mcomment region "^/$" "^\\$" fill comment
add-highlighter shared/k/comment region "(^| )/" "$" fill comment
add-highlighter shared/k/string region '\\?\K"' '\n[^ ]|(?<!\\)(?:\\\\)*"' group
add-highlighter shared/k/string/ fill string
add-highlighter shared/k/string/ regex "\\." 0:keyword

add-highlighter shared/k/code/ regex ";" 0:white
add-highlighter shared/k/code/ regex "[ \t]+$" 0:white,red
add-highlighter shared/k/code/ regex "[{}]" 0:white
add-highlighter shared/k/code/ regex "[\[\]\(\)]" 0:bright-black
add-highlighter shared/k/code/ regex '[+\-*%!&|<>=~,^#_$?@.:]:?' 0:keyword
add-highlighter shared/k/code/ regex "[\\/']:?" 0:green
add-highlighter shared/k/code/ regex "-?\d+([ijl]|[NW][ijl]?|[nw]|(\.\d+)?(e-?\d+)?)?" 0:value
add-highlighter shared/k/code/ regex "-?(0[NnWw])" 0:value
add-highlighter shared/k/code/ regex '[0-5]:' 0:keyword
add-highlighter shared/k/code/ regex "\b-" 0:keyword
add-highlighter shared/k/code/ regex "\b0x([\dA-Fa-f]{2})*" 0:string
add-highlighter shared/k/code/ regex "[01]+b" 0:value
add-highlighter shared/k/code/ regex "\b[A-Za-z][A-Za-z0-9\.]*" 0:yellow
add-highlighter shared/k/code/ regex "`([A-Za-z][A-Za-z0-9]*|\b0x([\dA-Fa-f]{2})*)" 0:bright-magenta

declare-user-mode k
define-command -hidden k-indent-on-new-line %`
    evaluate-commands -draft -itersel %_
        # preserve previous line indent
        try %{ execute-keys -draft <semicolon> K <a-&> }
        # copy # comments prefix
        try %{ execute-keys -draft <semicolon><c-s>k<a-x> s ^\h*\K/+\h* <ret> y<c-o>P<esc> }
        # indent after lines ending with { ⟨ [
        try %( execute-keys -draft k<a-x> <a-k> [{⟨\[]\h*$ <ret> j<a-gt> )
        # cleanup trailing white spaces on the previous line
        try %{ execute-keys -draft k<a-x> s \h+$ <ret>d }
     _
`

define-command -hidden k-indent-on-closing %`
    evaluate-commands -draft -itersel %_
        # align to opening bracket
        try %( execute-keys -draft <a-h> <a-k> ^\h*[}⟩\]]$ <ret> h m <a-S> 1<a-&> )
    _
`


define-command k-repl %`
    evaluate-commands %(
        repl-new
        repl-send-text "clear && rlwrap %opt{k_exec}
"
    )
`

define-command k-repl-from-selection %`
    evaluate-commands %(
        k-repl
        repl-send-text
    )
`

define-command k-execute-line %`
    evaluate-commands -draft %_
        execute-keys X
        k-repl-from-selection
    _
`

define-command k-run-file %`
    k-repl
    repl-send-text "\l %val{buffile}
"
`

map -docstring "Open a new K repl" global k r ": k-repl
"
map -docstring "Open a new K repl with the current selection executed" global k s ": k-repl-from-selection
"
map -docstring "Open a new K repl with the current line executed" global k x ": k-execute-line
"
map -docstring "Open a new K repl with the current file loaded" global k l ": k-run-file
"
¹
