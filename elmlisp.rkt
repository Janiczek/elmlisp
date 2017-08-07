#lang racket

; TODO: all 'module' definitions to the top, from whenever user or macro calls (module)
; TODO: all 'import' to the top, alphabetically sorted

; TODO: optionally use elm-format on the resulting file(s)?

(require "parse.rkt"
         "compile.rkt"
         "format.rkt")

; 1. read the file contents (TODO: allow reading from STDIN, and multiple files)
; https://bitbucket.org/ktg/l/src/57a5293aa0f040c81afd799364f3aaacaf8676fa/l++.rkt?at=master&fileviewer=file-view-default#l%2B%2B.rkt-26:31
(define file-contents (file->string "elm-examples/all-syntax.ell"))

; 2. wrap it into ( parentheses ) so that we can map over all the expressions
(define code (wrap-in-parens file-contents))

; 3. parse the string into s-expressions
(define parsed (parse code))

; 4. compile s-expressions into Elm source code string (running macros in the process)
(define compiled (format-compiled-code (map compile parsed)))

; 5. display the result (TODO: allow writing to a file / more files)
(displayln compiled)
