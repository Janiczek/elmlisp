#lang racket

(require threading
         "src/compile.rkt")

(define (with-color color string)
  (format "~a~a~a" color string "\033[0m"))

(define (red string)
  (with-color "\033[31m" string))

(define (green string)
  (with-color "\033[32m" string))

(define (list-files directory)
  (~>> directory
       (directory-list)
       (map path->string)))

(define (test-names files suffix)
  (~>> files
       (filter (lambda (file)
                 (string-suffix? file suffix)))
       (map (lambda (file)
              (string-trim file suffix #:right? #t)))))
  
(define (trim string)
  (string-trim string #:repeat? #t))

(define (output-exists test files suffix)
  (member (format "~a~a" test suffix) files))

(define (throw-output-doesnt-exist test)
 (raise-user-error (red (format "ERROR: Test '~a' doesn't have an output file." test))))

(define (throw-output-doesnt-match test expected-output actual-output)
 (raise-user-error (red (format "FAILURE: Test '~a' didn't pass:\n\nExpected:\n~a\n\nActual:\n~a\n"
                                test
                                expected-output
                                actual-output))))
  
(define (test-output test directory input-suffix output-suffix)
 (let* ([input           (file->string (format "~a/~a~a" directory test input-suffix))]
        [expected-output (trim (file->string (format "~a/~a~a" directory test output-suffix)))]
        [actual-output   (trim (compile input))])
   (when (not (equal? expected-output actual-output))
     (throw-output-doesnt-match test expected-output actual-output))))
  
(define (run-tests directory input-suffix output-suffix)
  (let* ([files (list-files directory)]
         [tests (test-names files input-suffix)])
   (for ([test tests])
        (when (not (output-exists test files output-suffix))
          (throw-output-doesnt-exist test))
        (test-output test directory input-suffix output-suffix))))

; ----------------------------------------------------------------

(define examples-directory "./examples")
(define tests-directory    "./tests")

(run-tests "./tests"    ".in"  ".out")
(run-tests "./examples" ".ell" ".elm")

(displayln (green "All tests passed."))
