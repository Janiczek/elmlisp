#lang racket

(require threading
         "src/compile.rkt")

(define (with-color color string)
  (format "~a~a~a" color string "\033[0m"))

(define (red string)
  (with-color "\033[31m" string))

(define (green string)
  (with-color "\033[32m" string))

(define test-directory "./tests")
(define test-files (~>> test-directory
                        (directory-list)
                        (map path->string)))
(define tests (~>> test-files
                   (filter (lambda (file)
                             (string-suffix? file ".in")))
                   (map (lambda (file)
                          (string-trim file ".in" #:right? #t)))))

(for ([test tests])
  (when (not (member (format "~a.out" test) test-files))
    (raise-user-error (red (format "ERROR: Test '~a' doesn't have an output file." test))))
  (let* ([input           (file->string (format "~a/~a.in"  test-directory test))]
         [expected-output (file->string (format "~a/~a.out" test-directory test))]
         [actual-output   (compile input)])
    (when (not (equal? expected-output actual-output))
      (raise-user-error (red (format "FAILURE: Test '~a' didn't pass:\n\nExpected:\n~a\nActual:\n~a"
                                     test
                                     expected-output
                                     actual-output))))))

(displayln (green "All tests passed."))