#lang racket

(provide is-exposed-adt?
         is-arrow-type?
         is-record?)

(define (is-exposed-adt? expr)
  (list? expr))

(define (is-arrow-type? expr)
  (and (list? expr)
       (eq? (first expr) '->)))
  

(define (is-record? expr)
  (and (list? expr)
       (eq? (first expr) 'elm-record)))
