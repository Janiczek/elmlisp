#lang racket

(provide is-exposed-adt?)

(define (is-exposed-adt? e)
  (list? e))
