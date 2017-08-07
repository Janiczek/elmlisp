#lang racket

(provide is-exposed-adt?
         is-arrow-type?)

(define (is-exposed-adt? expr)
  (list? expr))

(define (is-arrow-type? expr)
  (and (list? expr)
       (equal? (first expr) '->)))
  
