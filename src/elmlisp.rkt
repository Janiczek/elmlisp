#lang racket

; TODO: all 'module' definitions to the top, from whenever user or macro calls (module)
; TODO: all 'import' to the top, alphabetically sorted

; TODO: optionally use elm-format on the resulting file(s)?

(require "compile.rkt")

(provide compile)

(define version "0.0.3")

; 1. read the cmdline arguments (currently we only accept a filename to compile
(define arguments (current-command-line-arguments))

; 2. read the input (either from STDIN if no arguments, or from the files specified by arguments)
(define file-contents
  (if (equal? (vector-length arguments) 0)

    ; read from STDIN
    (begin
     (displayln (format "ElmLisp ~a" version))
     (displayln "Enter code (^D when done):")
     (port->string))

    ; read from a file
    (file->string (vector-ref arguments 0))))

; 6. display the result (TODO: allow writing to a file)
(displayln (compile file-contents))
