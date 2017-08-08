#lang racket

(require "compile.rkt")

(provide compile)

(define version "0.0.12")

; 1. read the cmdline arguments (currently we only accept a filename to compile
(define arguments (current-command-line-arguments))

; 2. read the input (either from STDIN if no arguments, or from the files specified by arguments)
(define file-contents
  (if (equal? (vector-length arguments) 0)

    ; read from STDIN
    (begin
     (displayln (format "ElmLisp ~a" version))
     (displayln "Enter code (^D when done):")
     (displayln "--------------------------")
     (port->string))

    ; read from a file
    (file->string (vector-ref arguments 0))))

; 3. compile the ElmLisp code to Elm code
(define elm-code (compile file-contents))

; 4. display it (TODO: allow writing to a file)
(displayln elm-code)
