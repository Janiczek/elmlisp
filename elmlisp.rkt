#lang racket

; TODO: all 'module' to the top
; TODO: all 'import' to the top

(require "readtable.rkt"
         "compile.rkt")

; TODO temporary crutch - when ready, put back the stdin/file behaviour
; https://bitbucket.org/ktg/l/src/57a5293aa0f040c81afd799364f3aaacaf8676fa/l++.rkt?at=master&fileviewer=file-view-default#l%2B%2B.rkt-26:31
(define code
  (file->string "elm-examples/all-syntax.ell"))

; wrap it all into one list
(set! code (string-append "(" code ")"))

; parse the string into Racket forms
; (with a few exceptions given by the readtable)
(define parsed
  (parameterize ([current-readtable (elmlisp-readtable)])
    (read (open-input-string code))))

; compile into Elm source code
(define compiled
  (~a (string-join
       (map compile parsed)
       "\n"
       #:after-last "\n")))

; TODO when ready, delete this and put back the "write to a file" behaviour
(displayln compiled)
