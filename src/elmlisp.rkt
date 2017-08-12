#lang racket

(require "compile.rkt")

(provide compile)

(define version "0.0.17")
(define program-name (format "ElmLisp ~a" version))

; 1. read the cmdline arguments (currently we only accept a filename to compile
(define arg-format?         (make-parameter #f))
(define arg-output-filename (make-parameter #f))
(define arg-filenames
  (command-line
   #:program program-name
   #:once-each
   (("-f" "--format") "Run elm-format (found on your PATH) on the resulting Elm code and return the result of that. Note that elm-format needs at least module declaration and a value definition to be present."
                      (arg-format? #t))
   (("-o") file
           "Place the output into <file>"
           (arg-output-filename file))
   #:args filenames
   filenames))

; 2. read the input (either from STDIN if no arguments, or from the files specified by arguments)
(define file-contents
  (case (length arg-filenames)

    ; read from STDIN
    [(0)
     (begin
      (displayln program-name)
      (displayln "Enter code (^D when done):")
      (displayln "--------------------------")
      (port->string))]

    ; read from a file
    [(1)
     (file->string (first arg-filenames))]

    [else
     (raise-user-error "ERROR: only one filename argument supported")]))
     

; 3. compile the ElmLisp code to Elm code
(define elm-code (compile file-contents))

; 4. possibly elm-format it
(define formatted-elm-code
  (if (arg-format?)
    (parameterize ([current-input-port (open-input-string elm-code)])
     (with-output-to-string
       (lambda () (system "elm-format --stdin"))))
    elm-code))

; 5. display it or write it to a file
(if (arg-output-filename)
  (begin
    (let ([out-port (open-output-file (arg-output-filename) #:exists 'replace)])
     (displayln formatted-elm-code out-port)
     (close-output-port out-port)))  
  (displayln formatted-elm-code))

