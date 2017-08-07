#lang racket

(provide wrap-in-parens
         format-compiled-code
         format-exposing
         format-type
         format-module
         format-type-definition
         format-arguments)
         ;format-cases

; when reading a file, wrap all its s-exprs into one list
(define (wrap-in-parens string)
 (string-append "(" string ")"))

; combine all Elm source code strings to one
(define (format-compiled-code list)
  (~a (string-join
        list
        "\n\n"
        #:after-last "\n")))

; used for "exposing (foo bar)"
;                    ^^^^^^^^^
; ------------------------------
; (foo bar baz) => foo, bar, baz
; (..)          => ..
; (foo)         => foo
; ((Msg (..)))  => Msg(..)
(define (format-exposing list)
  (string-join
    ; could be (map ~a list) but we are special-casing for Msg(..)
    (map (lambda (exposed)
           (if (and (list? exposed)
                    (equal? (second exposed)
                            '(..)))
             (format "~a(..)" (first exposed))
             (~a exposed)))       
         list)
    ", "))

; used for all kinds of type annotations
; basically remove outermost parens but otherwise leave as is
; --------------------------------
; TODO: what about records? will have to special-case here
; (elm-record (name String) (age Int))
; =>
; { name : String , age : Int }
; --------------------------------
; String          => String
; (Html Msg)      => Html Msg
; (Html (List a)) => Html (List a)
(define (format-type type)
  (if (list? type)
    (string-join (map ~a type) " ")
    (~a type)))

; allows module, port module
; --------------------------
; TODO: effect module - will have to research this one a bit!
(define (format-module e module-type)
  (case (length e)
    [(2)
     (format "~a ~a exposing (..)"
             module-type
             (second e))]
    [(4)
     (format "~a ~a exposing (~a)"
             module-type
             (second e)
             (format-exposing (fourth e)))])) 

; used for (type)
; ---------------
; (True False)       => True | False
; (Nothing (Just a)) => Nothing | Just a
(define (format-type-definition constructors)
  (string-join (map format-type constructors)
               "\n    | "))

; used in lambdas (maybe will be used in more places?)
; -------------------
; TODO: destructuring
; -------------------
; x     => x
; (x y) => x y
(define (format-arguments arguments)
  (if (list? arguments)
    (string-join (map ~a arguments) " ")
    (~a arguments)))

; TODO: format-cases
; will be used for (case)
; -----------------------
; ((True 1) (False 0))              => True -> 1 \n False -> 0
; ((Inc 1) ((IncBy amount) amount)) => Inc -> 1 \n IncBy amount -> amount
; -----------------------
;(define (format-cases cases)
;  (string-join ... ""))
