#lang racket

(provide wrap-in-parens
         format-compiled-code
         format-exposing
         format-type
         format-module
         format-type-definition
         format-arguments
         format-cases)

(require "helpers.rkt")

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
    (map (lambda (exposed)
           (if (is-exposed-adt? exposed)
               (format-exposed-adt exposed)
               (~a exposed)))       
         list)
    ", "))

(define (format-exposed-adt adt)
  (format "~a(~a)"
          (first adt)
          (string-join (map ~a (second adt)) ", ")))

; used for all kinds of type annotations
; basically remove outermost parens but otherwise leave as is
; with exception of (->)
; --------------------------------
; TODO: what about records? will have to special-case here
; (elm-record (name String) (age Int))
; =>
; { name : String , age : Int }
; --------------------------------
; String            => String
; (Html Msg)        => Html Msg
; (Html (List a))   => Html (List a)
; (-> Int String)   => Int -> String
; (-> Int (List a)) => Int -> List a
; (-> (-> a b) a b) => (a -> b) -> a -> b
(define (format-type type #:nested? [nested? #f])
  (cond
    [(is-arrow-type? type)
     (if nested?
       (wrap-in-parens (format-arrow-type type))
       (format-arrow-type type))]

    [(list? type)
     (string-join (map ~a type) " ")]

    [else
      (~a type)]))

(define (format-arrow-type type)
  (string-join (map (lambda (type-part)
                      (format-type type-part #:nested? #t))
                    (rest type))
               " -> "))

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

; ((True 1) (False 0))              => True -> 1 \n False -> 0
; ((Inc 1) ((IncBy amount) amount)) => Inc -> 1 \n IncBy amount -> amount
; -----------------------
(define (format-cases cases)
  "1")
