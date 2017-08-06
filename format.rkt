#lang racket

(provide format-exposing
         format-type
         format-module
         format-type-definition
         format-arguments
         ;format-cases
         )

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

; allows module, port module, effect module (that one is TODO)
(define (format-module e module-type)
  (format "~a ~a exposing (~a)"
          module-type
          (second e)
          (format-exposing (fourth e))))

; (True False)       => True | False
; (Nothing (Just a)) => Nothing | Just a
(define (format-type-definition constructors)
  (string-join (map format-type constructors) "\n    | "))

; (for lambda...)
; x     => x
; (x y) => x y
; TODO this is most likely not right - no destructuring etc.
(define (format-arguments arguments)
  (if (list? arguments)
      (string-join (map ~a arguments) " ")
      (~a arguments)))

; ((True 1) (False 0)) => True -> 1 \n False -> 0
;(define (format-cases cases)
;  (string-join ... ""))