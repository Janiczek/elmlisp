#lang racket

(provide format-exposing
         format-type)

; (foo bar baz) => foo, bar, baz
; (..)          => ..
; (foo)         => foo
; ((Msg (..)))  => Msg(..)
(define (format-exposing list)
  (string-join
   ; could be (map ~a list) but we are special casing for Msg(..)
   (map (lambda (exposed)
          (if (and (list? exposed)
                   (equal? (second exposed)
                           '(..)))
              (format "~a(..)" (first exposed))
              (~a exposed)))       
        list)
   ", "))

; String          => String
; (Html Msg)      => Html Msg
; (Html (List a)) => Html (List a)
(define (format-type type)
  (if (list? type)
      (string-join (map ~a type) " ")
      (~a type)))